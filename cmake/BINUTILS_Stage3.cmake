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

include(PTHREAD_Stage3)

set(BINUTILS_STAGE3_BYPRODUCTS
	"${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/bin/${DJGPP_TARGET_TRIPLET}-ld")

#
# This is the 'full' build that includes more features than the
# stage1/stage2 binutils.
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
ExternalProject_Add(BINUTILS_Stage3 DEPENDS PTHREAD_Stage3_Ninja
	PREFIX "${STAGE3_BINARY_DIR}"
	USES_TERMINAL_DOWNLOAD TRUE
	USES_TERMINAL_CONFIGURE TRUE
	USES_TERMINAL_BUILD TRUE
	USES_TERMINAL_INSTALL TRUE
	DOWNLOAD_DIR "${DOWNLOAD_DIRECTORY}"
	DOWNLOAD_EXTRACT_TIMESTAMP FALSE
	URL ${BNU_URL}
	URL_HASH ${BNU_HASH}

	PATCH_COMMAND
		# Apply patch to increase segment aligment to 64 bytes.
		${PATCH_EXE} -f -N -p1 < "${PATCHES_DIRECTORY}/bnu244-coff_section_alignment.patch"

	CONFIGURE_COMMAND
		${CMAKE_COMMAND} -E env LDFLAGS=-static --
		${SH_EXE} -c "'<SOURCE_DIR>/config.guess' | '${XARGS_EXE}' -I {}\
			'<SOURCE_DIR>/configure'\
				--build='{}'\
				--host='${DJGPP_HOST_TRIPLET}' \
				--target='${DJGPP_TARGET_TRIPLET}'\
				--prefix='${CMAKE_INSTALL_PREFIX}'\
				--with-sysroot='${STAGE3_BINARY_DIR}'\
				--with-build-sysroot='${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}'\
				--with-gcc-major-version-only\
				--enable-vtable-verify\
				--enable-year2038\
				--disable-werror\
				--enable-libstdcxx\
				--disable-libada\
				--disable-libgm2\
				--disable-libssp\
				--disable-nls\
				--enable-libquadmath\
				--disable-multilib\
				--disable-plugins"

	BUILD_COMMAND
		${MAKE_EXE} "-j${NJOBS}"

	INSTALL_COMMAND
		${MAKE_EXE} "DESTDIR=${STAGE3_BINARY_DIR}" "-j${NJOBS}" install-strip

	BUILD_BYPRODUCTS "${BINUTILS_STAGE3_BYPRODUCTS}"
)

add_custom_target(BINUTILS_Stage3_Ninja DEPENDS "${BINUTILS_STAGE3_BYPRODUCTS}")
add_dependencies(BINUTILS_Stage3_Ninja PTHREAD_Stage3_Ninja BINUTILS_Stage3)

# ex:set ts=2
