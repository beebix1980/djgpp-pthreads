#
# Build script for a DJGPP cross-compiler with POSIX threads (and std::thread)
# Copyright (C) 2026 by Alexander Bruines <alexander.bruines@gmail.com>
#
# This entire distribution, including any scripts and patches used to build
# it, are distributed under the terms described in the file COPYING.DJ.
#
# COPYING.DJ should be in the same directory as this file but can also be
# found at: https://www.delorie.com/djgpp/dl/ofc/simtel/v2/copying.dj
#
#
# SCRIPT VERSION: 2.0 'Enter the Ninja'
#
#
# NOTICE
# ------
#
# All applications produced with the DJGPP/GCC built by these build scripts
# must -if released- comply with the GNU General Public Licence version 2.
# The reason for this is that applications are statically linked to a
# modified DJGPP runtime (and other GPL'ed libraries).
#
#
# REQUIREMENTS
# ------------
#
# To build the DJGPP cross-compiler a lot of programs must be present on
# the system. For a Debian (based) distro it should be enough to install the
# following pacakges before running this script:
#
# $ sudo apt update && sudo apt install \
#     cmake ninja-build bison patch sed flex gcc g++ tar texinfo \
#     zlib1g-dev unzip zip zstd pigz libgmp-dev libmpfr-dev libmpc-dev
#
# If configuring with -DHAVE_WATT32=ON then these are also needed:
#
# $ sudo apt install nasm libslang2-dev
#
# Note that these script are meant to run on Linux, they have not been
# tested with MSYS or such on Windows (and never will be by me).
#
#
# USAGE
# -----
#
# To configure for building in a (new) sub-directory named 'build':
#
#   cmake [-G Ninja] -S <path-to-this-directory> -B ./build
#
# Using Ninja is optional.
# You can also use the following options (default values listed):
#
#   -DNJOBS=<N>
#   -DDJGPP_MARCH=i586
#   -DDJGPP_MTUNE=i586
#   -DHAVE_WATT32=OFF
#   -DCMAKE_INSTALL_PREFIX=/usr/local
#
# Where NJOBS is the number of parallel jobs, recommended:
#    logical cpu cores - 1, which is the default if not set explicitly.
#
# Values for DJGPP_MARCH and DJGPP_MTUNE are: i386, i486, i586, i686 and i786.
# These values are not only the defaults for the stage 3 gcc, all libraries
# are also compiled with those -march and -mtune settings.
#
# Notes: Do not use --parallel N or -j N.
#        Setting CMAKE_BUILD_PARALLEL_LEVEL overrides NJOBS.
#        Setting CMAKE_INSTALL_PREFIX to /usr is untested (ie. don't do that)
#
# To build DJGPP after configuration:
#
#		cmake --build ./build
#
# The build process consumes about 20GB of disk space.
# After building the third stage of the DJGPP cross-compiler it is
# packaged as a tarball. The tarball can be extracted (to /) manually
# or by running cmake in install mode with:
#
#		[sudo] cmake --install ./build
#
# An example toolchain file for using the DJGPP cross-compiler with (your)
# CMake based projects is available, see 'djgpp_toolchain.cmake'.
#

# dev note:
# Everything in these scripts that has the '_Ninja' tag is only there to make
# it build correctly with Ninja. The same is true for all the _BYPRODUCS vars.
# When removed the script still works with the Unix Makefiles generator, but
# the ninja fails to see the dependencies in the correct order and fails.

cmake_minimum_required(VERSION 3.24)
include(ExternalProject)
include(ProcessorCount)

project(
	djgpp-builder
	VERSION 2.0
	DESCRIPTION
		"Build a DJGPP cross-compiler with POSIX threads and std::thread supported."
	LANGUAGES C CXX)

# Selects the DJGPP 'flavour' to build.
set(DJGPP_MARCH "i586" CACHE STRING "DJGPP target processor [i386,i486,i586,i686,i786].")
set(DJGPP_MTUNE "i586" CACHE STRING "Optimize DJGPP code generation for this architecture [i386,i486,i586,i686,i786].")

# Optionally install WATT32
option(HAVE_WATT32 "Install WATT32 instead of a dummy libsocket." OFF)

# Where dowloaded files are placed.
set(DOWNLOAD_DIRECTORY "${PROJECT_SOURCE_DIR}/downloads")
#set(DOWNLOAD_DIRECTORY "${PROJECT_BINARY_DIR}/downloads")

# Where the patches and local source packages are.
set(PATCHES_DIRECTORY "${PROJECT_SOURCE_DIR}/patches")

# Some mirrors for downloading the source packages
set(DJGPP_MIRRORS1 "https://mirror.koddos.net/djgpp/current")
set(DJGPP_MIRRORS2 "https://ftp.fu-berlin.de/pc/languages/djgpp/current")
set(DJGPP_MIRRORS3 "http://www.delorie.com/pub/djgpp/current")
set(GNU_MIRROR "https://ftpmirror.gnu.org")

# These are used to update the config.guess in the pth207s.zip sources.
set(CONFIG_GUESS_URL "https://git.savannah.gnu.org/gitweb/?p=config.git$<SEMICOLON>a=blob_plain$<SEMICOLON>f=config.guess$<SEMICOLON>hb=HEAD")
set(CONFIG_SUB_URL "https://git.savannah.gnu.org/gitweb/?p=config.git$<SEMICOLON>a=blob_plain$<SEMICOLON>f=config.sub$<SEMICOLON>hb=HEAD")

# Download information for the binutils source tarball
set(BNU_VERSION "2.46.0")
set(BNU_NAME    "binutils-${BNU_VERSION}")
set(BNU_ZIP     "${BNU_NAME}.tar.xz")
set(BNU_URL     "${GNU_MIRROR}/binutils/${BNU_ZIP}")
set(BNU_HASH    "SHA256=d75a94f4d73e7a4086f7513e67e439e8fcdcbb726ffe63f4661744e6256b2cf2")

# Download information for the gcc source tarball
set(GCC_VERSION  "15.2.0")
set(GCC_NAME     "gcc-${GCC_VERSION}")
set(GCC_ZIP      "${GCC_NAME}.tar.xz")
set(GCC_URL      "${GNU_MIRROR}/gcc/gcc-${GCC_VERSION}/${GCC_ZIP}")
set(GCC_HASH     "SHA256=438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e")

# Download information for the Pth207 source tarball
set(PTHREAD_ZIP  "pth207s.zip")
set(PTHREAD_URL1 "${DJGPP_MIRRORS1}/v2gnu/${PTHREAD_ZIP}")
set(PTHREAD_URL2 "${DJGPP_MIRRORS2}/v2gnu/${PTHREAD_ZIP}")
set(PTHREAD_URL3 "${DJGPP_MIRRORS3}/v2gnu/${PTHREAD_ZIP}")
set(PTHREAD_HASH "SHA256=6a233a0a314437e27dfa4b6bfab6081e532235e62aad27700d0d9cabd0025862")

# Download information for the watt32s source tarball
set(WATT32_ZIP  "watt32s.zip")
set(WATT32_URL  "http://watt-32.net/${WATT32_ZIP}")
set(WATT32_HASH "SHA256=93388a24299ecb49dab8262e1ba1e1102aa26cb7b5fdd8cca945e4ef43d6fad1")

# Download information for the dummy libsocket tarball
set(PTHSOCK_ZIP     "pthsock-1.1.tar.gz")
set(PTHSOCK_URL     "${PATCHES_DIRECTORY}/${PTHSOCK_ZIP}")
set(PTHSOCK_HASH    "SHA256=34e0eb39fa3b5e5f31c25f94fefe180c25d801048b4d51a1b95b7fc2e96380f5")

# Download information for the DJGPP distro files.
set(DJLSR_ZIP    "djlsr205.zip")
set(DJLSR_SHA256 "SHA256=80690b6e44ff8bc6c6081fca1f4faeba1591c4490b76ef0ec8b35847baa5deea")
set(DJLSR_URL1   "${DJGPP_MIRRORS1}/v2/${DJLSR_ZIP}")
set(DJLSR_URL2   "${DJGPP_MIRRORS2}/v2/${DJLSR_ZIP}")
set(DJLSR_URL3   "${DJGPP_MIRRORS3}/v2/${DJLSR_ZIP}")
set(DJDEV_ZIP    "djdev205.zip")
set(DJDEV_SHA256 "SHA256=4557dfb6c161d326680ae5fa71f0098ac49425a1b11b90a020b83162eb705dda")
set(DJDEV_URL1   "${DJGPP_MIRRORS1}/v2/${DJDEV_ZIP}")
set(DJDEV_URL2   "${DJGPP_MIRRORS2}/v2/${DJDEV_ZIP}")
set(DJDEV_URL3   "${DJGPP_MIRRORS3}/v2/${DJDEV_ZIP}")
set(DJCRX_ZIP    "djcrx205.zip")
set(DJCRX_SHA256 "SHA256=22274ed8d5ee57cf7ccf161f5e1684fd1c0192068724a7d34e1bde168041ca60")
set(DJCRX_URL1   "${DJGPP_MIRRORS1}/v2/${DJCRX_ZIP}")
set(DJCRX_URL2   "${DJGPP_MIRRORS2}/v2/${DJCRX_ZIP}")
set(DJCRX_URL3   "${DJGPP_MIRRORS3}/v2/${DJCRX_ZIP}")
set(DJTZS_ZIP    "djtzs205.zip")
set(DJTZS_SHA256 "SHA256=79e7214af130b0715a0dafb363b407018ec4459cfeb07e152c6e95b282a6d32e")
set(DJTZS_URL1   "${DJGPP_MIRRORS1}/v2/${DJTZS_ZIP}")
set(DJTZS_URL2   "${DJGPP_MIRRORS2}/v2/${DJTZS_ZIP}")
set(DJTZS_URL3   "${DJGPP_MIRRORS3}/v2/${DJTZS_ZIP}")
set(DJTZN_ZIP    "djtzn205.zip")
set(DJTZN_SHA256 "SHA256=1f601b6e95a1b0dfc42f7d72b5b92a44538077f9fe0663889d8edd71d7ab4445")
set(DJTZN_URL1   "${DJGPP_MIRRORS1}/v2/${DJTZN_ZIP}")
set(DJTZN_URL2   "${DJGPP_MIRRORS2}/v2/${DJTZN_ZIP}")
set(DJTZN_URL3   "${DJGPP_MIRRORS3}/v2/${DJTZN_ZIP}")

# Name of the tarball with DJGPP binaries to be created.
set(DJGPP_TARBALL "djgpp205-${DJGPP_MARCH}_gcc-${GCC_VERSION}-pthread.tar.gz")

# The target system triplet for the DJGPP cross-compilers
set(DJGPP_TARGET_TRIPLET "${DJGPP_MARCH}-pc-msdosdjgpp")

# Installation directories for the 3 build stages.
set(STAGE1_BINARY_DIR "${PROJECT_BINARY_DIR}/Stage1")
set(STAGE2_BINARY_DIR "${PROJECT_BINARY_DIR}/Stage2")
set(STAGE3_BINARY_DIR "${PROJECT_BINARY_DIR}/Stage3")

# Set the number of parallel jobs for the build process.
if(NOT DEFINED NJOBS)
	ProcessorCount(count)
	message(STATUS "Number of logical CPU cores: ${count}.")
	math(EXPR count "${count} - 1")
	set(NJOBS "${count}" CACHE STRING "Nr of parallel jobs.")
	message(STATUS "Setting number of parallel jobs to ${NJOBS} (auto).")
else()
	message(STATUS "Number of parallel jobs is ${NJOBS}.")
endif()

# Locate all the external applications and libraries needed.
find_program(SH_EXE sh REQUIRED)
find_program(FIND_EXE find REQUIRED)
find_program(MAKE_EXE make REQUIRED)
find_program(PATCH_EXE patch REQUIRED)
find_program(SED_EXE sed REQUIRED)
find_program(TAR_EXE tar REQUIRED)
find_program(ZIP_EXE zip REQUIRED)
find_program(PIGZ_EXE pigz REQUIRED)
find_program(UNZIP_EXE unzip REQUIRED)
find_program(SHA256SUM_EXE sha256sum REQUIRED)
find_program(XARGS_EXE xargs REQUIRED)
find_program(BISON_EXE bison REQUIRED)
find_program(FLEX_EXE flex REQUIRED)
find_program(MAKEINFO_EXE makeinfo REQUIRED)
find_path(GMP_HEADER_PATH gmp.h REQUIRED)
find_library(GMP_LIBRARIES gmp REQUIRED)
find_path(MPFR_HEADER_PATH mpfr.h REQUIRED)
find_library(MPFR_LIBRARIES mpfr REQUIRED)
find_path(MPC_HEADER_PATH mpc.h REQUIRED)
find_library(MPC_LIBRARIES mpc REQUIRED)
if(HAVE_WATT32)
find_program(NASM_EXE nasm REQUIRED)
find_path(SLANG_HEADER_PATH slang.h REQUIRED)
find_library(SLANG_LIBRARIES slang REQUIRED)
endif()

# This adds the entire 'chain' of .cmake files with one ExternalProject each.
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
include(GCC_Stage3)

# Packaging is part of the GCC_Stage3 target and depends on the time-stamp
# of the GCC_Stage3-install step.
ExternalProject_Get_Property(GCC_Stage3 INSTALL_DIR STAMP_DIR)
cmake_path(GET CMAKE_INSTALL_PREFIX PARENT_PATH PREFIX_STEM)
string(REPLACE "/" "" PREFIX_STEM ${PREFIX_STEM})
set(INSTALL_STAMP "${STAMP_DIR}/GCC_Stage3-install")
add_custom_command(
	OUTPUT "${DJGPP_TARBALL}"
	DEPENDS "${INSTALL_STAMP}"
	COMMENT "Creating DJGPP in '${DJGPP_TARBALL}'"
	COMMAND ${SH_EXE} -c "\
	cp -f '${PROJECT_SOURCE_DIR}/README' \
	'${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/readme.2nd' && \
	cd '${PROJECT_BINARY_DIR}' && ${TAR_EXE} --owner=root --group=root \
	--exclude=cross --exclude=manifest --use-compress-program=pigz \
	-C '${INSTALL_DIR}' -cf '${DJGPP_TARBALL}' ${PREFIX_STEM}"
	VERBATIM
)

# The default target depends on building the DJGPP tarball.
add_custom_target(djgpp ALL DEPENDS "${DJGPP_TARBALL}")

# Ninja needs a little more convincing.
add_dependencies(djgpp GCC_Stage3_Ninja)

# In install mode the DJGPP_TARBALL is extracted to /CMAKE_INSTALL_PREFIX
install(CODE
	"if(NOT EXISTS \"${PROJECT_BINARY_DIR}/${DJGPP_TARBALL}\")
		message(FATAL_ERROR \"The 'djgpp' target must be built before installation!\")
	endif()
	execute_process(
		COMMAND ${CMAKE_COMMAND} -E cmake_echo_color --green \"Installing DJGPP to ${CMAKE_INSTALL_PREFIX}\"
	)
	execute_process(
		WORKING_DIRECTORY \"${PROJECT_BINARY_DIR}\"
		COMMAND ${SH_EXE} -c \"${TAR_EXE} --overwrite -C / -xf '${DJGPP_TARBALL}'\"
		RESULT_VARIABLE _tar_result
	)
	if(NOT _tar_result EQUAL 0)
		message(FATAL_ERROR \"Failed to install DJGPP to ${CMAKE_INSTALL_PREFIX}\")
	endif()
	")

# A 'dist' target to create our own source tarball.
add_custom_command(
	OUTPUT "${PROJECT_NAME}-v${PROJECT_VERSION}.tar.gz"
	COMMENT "Creating '${PROJECT_NAME}-v${PROJECT_VERSION}.tar.gz"
	WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
	COMMAND ${SH_EXE} -c "${TAR_EXE} \
	-caf ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-v${PROJECT_VERSION}.tar.gz \
	cmake patches CMakeLists.txt README djgpp_toolchain.cmake copying* \
	build-djgpp-i?86.sh downloads/config.guess downloads/config.sub"
	VERBATIM)

add_custom_target(dist DEPENDS "${PROJECT_NAME}-v${PROJECT_VERSION}.tar.gz")

message(STATUS "Setting DJGPP target triplet to ${DJGPP_TARGET_TRIPLET}")
message(STATUS "Setting DJGPP default -march= to ${DJGPP_MARCH}")
message(STATUS "Setting DJGPP default -mtune= to ${DJGPP_MARCH}")
if(HAVE_WATT32)
	message(STATUS "Using WATT32 as sockets library.")
else()
	message(STATUS "Using a dummy sockets library.")
endif()

# ex:set ts=2
