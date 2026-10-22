#!/bin/bash
set -e
echo "PHP installing extensions using php docker tools"

## configure
docker-php-ext-configure gd --enable-gd --with-jpeg --with-webp --with-freetype --with-xpm
docker-php-ext-configure zip --with-zip

## skip extensions the base image already ships compiled in (e.g. opcache since PHP 8.5)
EXTENSIONS=""
for ext in dom gd intl mbstring mysqli opcache pdo pdo_mysql xsl zip; do
    loaded_name=${ext}
    [ "${ext}" = "opcache" ] && loaded_name="Zend OPcache"
    if php -r "exit(extension_loaded('${loaded_name}') ? 0 : 1);"; then
        echo "Extension ${ext} is already built in - skipping"
    else
        EXTENSIONS="${EXTENSIONS} ${ext}"
    fi
done

## install (uses all cores but 4 to keep systems responsible - minimum 1)
docker-php-ext-install -j$(nproc --ignore 4) ${EXTENSIONS}

## enable
docker-php-ext-enable ${EXTENSIONS}
