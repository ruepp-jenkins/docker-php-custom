#!/bin/bash

# install extensions
docker-php-ext-install mysqli pdo pdo_mysql

# enable extensions
docker-php-ext-enable mysqli pdo pdo_mysql
