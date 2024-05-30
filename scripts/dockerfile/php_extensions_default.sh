#!/bin/bash
set -e
echo "PHP installing extensions using php docker tools"

## configure
docker-php-ext-configure gd --enable-gd --with-jpeg --with-webp --with-freetype --with-xpm
docker-php-ext-configure zip --with-zip

## install (uses all cores but 4 to keep systems responsible - minimum 1)
docker-php-ext-install -j$(nproc --ignore 4) dom gd intl mbstring mysqli opcache pdo pdo_mysql xsl zip

## enable
docker-php-ext-enable dom gd intl mbstring mysqli opcache pdo pdo_mysql xsl zip
