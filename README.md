# general

Personal used php image with pre installed extensions using the official PHP images as base image.

# how to use

See original php image: https://hub.docker.com/_/php

Adress of the images: https://hub.docker.com/r/ruepp/php-custom

# additional PHP extensions

All additional PHP extensions and Apache modules are listed in [extensions.conf](scripts/dockerfile/extensions.conf). Every built image is tested against this list before it is pushed (see [test_image.sh](scripts/test_image.sh)).
