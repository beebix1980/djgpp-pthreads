#!/bin/sh
#sudo apt install -y bison flex curl gcc g++ make texinfo zlib1g-dev unzip gcc-mingw-w64-i686 g++-mingw-w64-i686 \
gcc-multilib g++-multilib patch zip pigz ninja-build libgmp-dev libmpfr-dev libmpc-dev libisl-dev inotify-tools

set -e
rm -rf ./build-windows
cmake -G Ninja -S . -B ./build-windows \
    -DCMAKE_TOOLCHAIN_FILE=mingw-w64.cmake \
    -DCMAKE_MAKE_PROGRAM=/usr/bin/ninja \
    -DCMAKE_C_COMPILER=/usr/bin/i686-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=/usr/bin/i686-w64-mingw32-g++ \
    -DGMP_HEADER_PATH:PATH=/usr/include/x86_64-linux-gnu \
    -DGMP_LIBRARIES:FILEPATH=/usr/lib/x86_64-linux-gnu/libgmp.so \
    -DMPFR_HEADER_PATH:PATH=/usr/include \
    -DMPFR_LIBRARIES:FILEPATH=/usr/lib/x86_64-linux-gnu/libmpfr.so \
    -DMPC_HEADER_PATH:PATH=/usr/include \
    -DMPC_LIBRARIES:FILEPATH=/usr/lib/x86_64-linux-gnu/libmpc.so \
    -DDJGPP_TARGET=i586-pc-msdosdjgpp

cmake --build ./build-windows
echo "You may now install the DJGPP binaries tarball with:"
echo "[sudo] cmake --install ./build-i586"

