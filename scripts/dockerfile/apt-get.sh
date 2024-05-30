#!/bin/bash
set -e
echo "Install packages"

apt-get update
apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libonig-dev \
    libmagickcore-6.q16-6-extra \
    libmagickwand-dev \
    libpng-dev \
    libwebp-dev \
    libxml2-dev \
    libxpm-dev \
    libxslt1-dev \
    libzip-dev \
    zlib1g-dev
