#!/bin/bash
set -e
echo "PHP installing extensions using pecl"

## install
printf '\n' | pecl install -fa imagick

## enable
docker-php-ext-enable imagick
