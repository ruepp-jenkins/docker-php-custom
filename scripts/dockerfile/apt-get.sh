#!/bin/bash
set -e
echo "Install packages"

apt-get update
apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpng-dev \
    libwebp-dev \
    zlib1g-dev
