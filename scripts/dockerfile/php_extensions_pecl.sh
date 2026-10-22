#!/bin/bash
set -e
echo "PHP installing extensions using pecl"

CONF="$(dirname "$0")/extensions.conf"

while read -r type name; do
    ## install
    printf '\n' | pecl install -fa "${name}"

    ## enable
    docker-php-ext-enable "${name}"
done < <(grep -E '^pecl[[:space:]]' "${CONF}")
