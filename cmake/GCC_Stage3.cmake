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

# Stage 3 / Package 4 : DJGPP cross-compiler (GCC)

include(BINUTILS_Stage3)

set(GCC_STAGE3_BYPRODUCTS
	"${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/bin/${DJGPP_TARGET_TRIPLET}-gcc")

# Final build of GCC.
#
# This is the 'full' build that includes POSIX threads and more then just
# the C compiler.
#
# To build DJGPP/GCC in a sysroot (eg. STAGE3_BINARY_DIR) with a prefix
# (eg. CMAKE_INSTALL_PREFIX) then configuring using --prefix= and --with-sysroot=
# alone is not enough because the target differs from the host. This means that
# --with-build-sysroot must also be setup correctly and point to the target
# directory (eg. 'STAGE3_BINARY_DIR/CMAKE_INSTALL_PREFIX/DJGPP_TARGET_TRIPLET').
# For DJGPP the native_system_header_dir must also be set, otherwise it will
# default to 'SYSROOT/TARGET/dev/env/DJDIR/include' when building libgcc.
# So it must be set to '/include' in order to work (on Linux).
# The build must also be able to find the target as/ld. This can be done
# with either --with-as/--with-ld, or by setting the PATH to include the target
# binaries directory (eg. STAGE3_BINARY_DIR/CMAKE_INSTALL_PREFIX/bin).
# Binutils must be configured the same and be previously installed to the sysroot.
#
ExternalProject_Add(GCC_Stage3 DEPENDS BINUTILS_Stage3_Ninja
	PREFIX "${STAGE3_BINARY_DIR}"
	USES_TERMINAL_DOWNLOAD TRUE
	USES_TERMINAL_CONFIGURE TRUE
	USES_TERMINAL_BUILD TRUE
	USES_TERMINAL_INSTALL TRUE
	DOWNLOAD_DIR "${DOWNLOAD_DIRECTORY}"
	DOWNLOAD_EXTRACT_TIMESTAMP FALSE
	URL	${GCC_URL}
	URL_HASH ${GCC_HASH}

	PATCH_COMMAND
		# Ninja: Ensure that pthread.h is installed before this point.
		${CMAKE_COMMAND} -E cmake_echo_color --green
			"Enter the Ninja: ${PTHREAD_STAGE3_BYPRODUCTS}" &&

		# Apply patches
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc-14.2.0.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-max_ofile_alignment.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-limits.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-putwc.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-pth207.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc152-ops-common.patch" &&

		# Make a backup of pthread.h
		${CMAKE_COMMAND} -E make_directory "<TMP_DIR>" &&
		${CMAKE_COMMAND} -E copy
			"${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/include/pthread.h"
			"<TMP_DIR>/pthread.h"

	CONFIGURE_COMMAND
		# Ninja: Ensure that stage 3 binutils/libc/libsocket/libpthread are installed before this point.
		${CMAKE_COMMAND} -E cmake_echo_color --green "Enter the Ninja:"
			"${BINUTILS_STAGE3_BYPRODUCTS} ${DJLSR_STAGE3_BYPRODUCTS}"
			"${PTHSOCK_STAGE3_BYPRODUCTS} ${PTHREAD_STAGE3_BYPRODUCTS}" &&

		# Configure
		${CMAKE_COMMAND} -E env "PATH=${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/bin:$ENV{PATH}" --
		${SH_EXE} -c "'<SOURCE_DIR>/config.guess' | '${XARGS_EXE}' -I {}\
				'<SOURCE_DIR>/configure'\
					--prefix='${CMAKE_INSTALL_PREFIX}'\
					--with-sysroot='${STAGE3_BINARY_DIR}'\
					--with-build-sysroot='${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}'\
					--with-native-system-header-dir='/include'\
					--build='{}'\
					--host='{}'\
					--target='${DJGPP_TARGET_TRIPLET}'\
					--enable-checking=release\
					--with-gcc-major-version-only\
					--with-cpu=${DJGPP_MARCH}\
					--with-tune=${DJGPP_MTUNE}\
					--with-pkgversion='DJGPP 2.05'\
					--enable-languages=c,c++,objc,obj-c++,fortran\
					--enable-libquadmath-support\
					--enable-libstdcxx-filesystem-ts\
					--enable-year2038\
					--enable-vtable-verify\
					--with-system-zlib\
					--enable-host-pie\
					--enable-host-shared\
					--disable-nls\
					--disable-libstdcxx-pch\
					--enable-cld\
					--disable-multilib\
					--disable-plugins"

	# Temporarely modify pthread.h for compiling gcc:
	# When building gcc the thread-aware functions must always be used
	# and this is the easiest method to do it...
	BUILD_COMMAND
		# Restore pthread.h
		${CMAKE_COMMAND} -E copy
			"<TMP_DIR>/pthread.h"
			"${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/include/" &&

		# Modify pthread.h
	  ${SED_EXE} -i
	  	"s/defined(_REENTRANT)/1/"
	  	"${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/include/pthread.h" &&

	  # Build gcc
		${CMAKE_COMMAND} -E env "PATH=${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/bin:$ENV{PATH}" --
		${MAKE_EXE} "-j${NJOBS}" &&

		# Restore pthread.h
		${CMAKE_COMMAND} -E copy
			"<TMP_DIR>/pthread.h"
			"${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/include/"

	INSTALL_COMMAND
		${CMAKE_COMMAND} -E env
			"PATH=${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/bin:$ENV{PATH}" --
			${MAKE_EXE} "DESTDIR=${STAGE3_BINARY_DIR}" "-j${NJOBS}" install-strip

	BUILD_BYPRODUCTS
		"${GCC_STAGE3_BYPRODUCTS}"
)

add_custom_target(GCC_Stage3_Ninja DEPENDS "${GCC_STAGE3_BYPRODUCTS}")
add_dependencies(GCC_Stage3_Ninja BINUTILS_Stage3_Ninja GCC_Stage3)

set(STAGE3_BYPRODUCTS
	"${BINUTILS_STAGE3_BYPRODUCTS} ${DJLSR_STAGE3_BYPRODUCTS}"
	"${PTHSOCK_STAGE3_BYPRODUCTS} ${PTHREAD_STAGE3_BYPRODUCTS}"
	"${GCC_STAGE3_BYPRODUCTS}")

# ex:set ts=2
