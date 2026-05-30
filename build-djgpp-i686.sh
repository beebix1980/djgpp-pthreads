#!/bin/sh

set -e

cmake -G Ninja -S . -B ./build-i686 \
 -DDJGPP_MARCH=i686 -DDJGPP_MTUNE=i686 -DHAVE_WATT32=OFF \
 -DCMAKE_INSTALL_PREFIX=/usr/local

cmake --build ./build-i686

echo "You may now install the DJGPP binaries tarball with:"
echo "[sudo] cmake --install ./build-i586"

