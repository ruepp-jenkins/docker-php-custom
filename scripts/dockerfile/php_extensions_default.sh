#!/bin/bash
set -e
echo "Installing extensions using php docker tools"

## configure
docker-php-ext-configure gd --enable-gd --with-jpeg --with-webp --with-freetype --with-xpm

## install
docker-php-ext-install dom gd intl mbstring mysqli opcache pdo pdo_mysql xsl zip

## enable
docker-php-ext-enable dom gd intl mbstring mysqli opcache pdo pdo_mysql xsl zip
