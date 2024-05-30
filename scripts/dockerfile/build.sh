#!/bin/bash
set -e
echo "Start build process"

# avoid some dialogs
export DEBIAN_FRONTEND=noninteractive

# make all .sh scripts executable
find /build -type f -iname "*.sh" -exec chmod +x {} \;

# preparations
/build/apt-get.sh

# determinate build platform
. /build/platforms/${TARGETPLATFORM}.sh

# installations
/build/php_extensions_default.sh
/build/php_extensions_pecl.sh

# cleanup
/build/php_cleanup.sh
/build/cleanup.sh
