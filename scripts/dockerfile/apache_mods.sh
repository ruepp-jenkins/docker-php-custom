#!/bin/bash
set -e
echo "Enabling apache2 mods"

CONF="$(dirname "$0")/extensions.conf"

while read -r type name; do
    a2enmod "${name}"
done < <(grep -E '^apache[[:space:]]' "${CONF}")
