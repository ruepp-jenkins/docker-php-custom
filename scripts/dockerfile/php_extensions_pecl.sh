#!/bin/bash
set -e
echo "Installing extensions using pecl"

## install
printf '\n' | pecl install -fa imagick

## enable
docker-php-ext-enable imagick
