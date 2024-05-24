#!/bin/bash

# configure
docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype

# install extensions
docker-php-ext-install gd mysqli

# enable extensions
docker-php-ext-enable gd mysqli
