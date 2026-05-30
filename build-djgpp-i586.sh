#!/bin/sh

set -e

cmake -G Ninja -S . -B ./build-i586 \
 -DDJGPP_MARCH=i586 -DDJGPP_MTUNE=i586 -DHAVE_WATT32=OFF \
 -DCMAKE_INSTALL_PREFIX=/usr/local

cmake --build ./build-i586

echo "You may now install the DJGPP binaries tarball with:"
echo "[sudo] cmake --install ./build-i586"

