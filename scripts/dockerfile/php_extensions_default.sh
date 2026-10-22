#!/bin/bash
set -e
echo "PHP installing extensions using php docker tools"

CONF="$(dirname "$0")/extensions.conf"

## configure
while read -r type name args; do
    if [ -n "${args}" ]; then
        docker-php-ext-configure "${name}" ${args}
    fi
done < <(grep -E '^ext[[:space:]]' "${CONF}")

## skip extensions the base image already ships compiled in (e.g. opcache since PHP 8.5)
EXTENSIONS=""
while read -r type name args; do
    # module names are compared lowercase without the "Zend " prefix (opcache is listed as "Zend OPcache")
    if php -m | tr 'A-Z' 'a-z' | sed 's/^zend //' | grep -qx "${name}"; then
        echo "Extension ${name} is already built in - skipping"
    else
        EXTENSIONS="${EXTENSIONS} ${name}"
    fi
done < <(grep -E '^ext[[:space:]]' "${CONF}")

## install (uses all cores but 4 to keep systems responsible - minimum 1)
docker-php-ext-install -j$(nproc --ignore 4) ${EXTENSIONS}

## enable
docker-php-ext-enable ${EXTENSIONS}
