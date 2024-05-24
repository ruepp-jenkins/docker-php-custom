#!/bin/bash
set -e
echo "Start build process"

# avoid some dialogs
export DEBIAN_FRONTEND=noninteractive

find /build -type f -iname "*.sh" -exec chmod +x {} \;

# preparations
/build/apt-get.sh
/build/tzdata.sh

# determinate build platform
. /build/platforms/${TARGETPLATFORM}.sh

# installations
/build/php.sh

# cleanup
/build/cleanup.sh
