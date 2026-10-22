#!/bin/bash
# Smoke test for a built image. Usage: scripts/test_image.sh <image> <dockerfile>
# Everything that is expected to be installed is read from scripts/dockerfile/extensions.conf.
# Exits non-zero if anything is missing or if php/apache report errors (cli, phpinfo or logs).
set -u

IMAGE=$1
DOCKERFILE=$2
CONF=scripts/dockerfile/extensions.conf
NAME="buildtest-$$"
FAILS=0

fail() { echo "  FAIL: $*"; FAILS=$((FAILS+1)); }
ok() { echo "  ok: $*"; }

cleanup() { docker rm -f "${NAME}" >/dev/null 2>&1; }
trap cleanup EXIT

echo "Testing image ${IMAGE}"
docker run -d --name "${NAME}" "${IMAGE}" >/dev/null || { echo "  FAIL: container did not start"; exit 1; }
docker exec "${NAME}" sh -c "echo '<?php phpinfo();' > /var/www/html/phpinfo.php"

# fetch phpinfo through apache (retry until apache is up)
WEB=""
for i in $(seq 1 30); do
    WEB=$(docker exec "${NAME}" php -r 'echo @file_get_contents("http://localhost/phpinfo.php");' 2>/dev/null)
    [ -n "${WEB}" ] && break
    sleep 1
done
if echo "${WEB}" | grep -q "PHP Version"; then ok "phpinfo reachable through apache"; else fail "phpinfo not reachable through apache"; fi

# errors reported by cli, phpinfo or the container logs
ERROR_LINE='^(PHP )?(Warning|Fatal error|Parse error|Notice|Deprecated)'
CLI_OUT=$(docker exec "${NAME}" sh -c 'php -m; php -i' 2>&1)
if echo "${CLI_OUT}" | grep -E "${ERROR_LINE}"; then fail "php cli reports errors"; else ok "php cli (php -m / php -i) is clean"; fi
if echo "${WEB}" | grep -E "${ERROR_LINE}|<b>(Warning|Fatal error|Parse error|Notice|Deprecated)</b>"; then fail "phpinfo reports errors"; else ok "phpinfo is clean"; fi
if docker logs "${NAME}" 2>&1 | grep -E 'PHP (Warning|Fatal|Parse|Notice|Deprecated|Startup)|:(error|crit|alert|emerg)\]'; then fail "container logs contain errors"; else ok "container logs are clean"; fi

# php extensions from the config must be loaded and listed in phpinfo
MODS=$(docker exec "${NAME}" php -m | grep -v '^\[' | grep -v '^$')
while read -r type name rest; do
    # module names are compared lowercase without the "Zend " prefix (opcache is listed as "Zend OPcache")
    actual=$(echo "${MODS}" | awk -v n="${name}" '{l=tolower($0); sub(/^zend /,"",l); if (l==n) {print; exit}}')
    if [ -z "${actual}" ]; then fail "extension ${name} is not loaded"; continue; fi
    anchor="module_$(echo "${actual}" | tr 'A-Z ' 'a-z+')"
    if echo "${WEB}" | grep -q "name=\"${anchor}\""; then ok "extension ${name} loaded and listed in phpinfo"; else fail "extension ${name} is loaded but missing in phpinfo"; fi
done < <(grep -E '^(ext|pecl)[[:space:]]' "${CONF}")

# apache modules from the config
APACHE_MODS=$(docker exec "${NAME}" apache2ctl -M 2>/dev/null)
while read -r type name rest; do
    if echo "${APACHE_MODS}" | grep -q " ${name}_module "; then ok "apache module ${name} loaded"; else fail "apache module ${name} is not loaded"; fi
done < <(grep -E '^apache[[:space:]]' "${CONF}")

# nothing the base image ships may be lost
BASE_IMAGE=$(sed -n 's/^FROM[[:space:]]\+\([^[:space:]]\+\).*/\1/p' "${DOCKERFILE}" | head -n 1)
MISSING=$(comm -23 <(docker run --rm "${BASE_IMAGE}" php -m | grep -v '^\[' | grep -v '^$' | sort) <(echo "${MODS}" | sort))
if [ -z "${MISSING}" ]; then ok "all modules of ${BASE_IMAGE} are still present"; else fail "modules missing compared to ${BASE_IMAGE}: $(echo ${MISSING})"; fi

# optional smoke checks from the config
while read -r type name code; do
    OUT=$(docker exec "${NAME}" php -r "exit((${code}) ? 0 : 1);" 2>&1)
    if [ $? -eq 0 ] && [ -z "${OUT}" ]; then ok "smoke check ${name}"; else fail "smoke check ${name} ${OUT}"; fi
done < <(grep -E '^smoke[[:space:]]' "${CONF}")

if [ "${FAILS}" -gt 0 ]; then echo "Test of ${IMAGE} FAILED (${FAILS} problem(s))"; exit 1; fi
echo "Test of ${IMAGE} passed"
