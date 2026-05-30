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

include(PTHREAD_Stage2)

set(BINUTILS_STAGE2_BYPRODUCTS
	"${STAGE2_BINARY_DIR}/bin/${DJGPP_TARGET_TRIPLET}-ld")

ExternalProject_Add(BINUTILS_Stage2 DEPENDS PTHREAD_Stage2_Ninja
	PREFIX "${STAGE2_BINARY_DIR}"
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
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/bnu244-coff_section_alignment.patch"

	CONFIGURE_COMMAND
		${SH_EXE} -c "'<SOURCE_DIR>/config.guess' | '${XARGS_EXE}' -I {} \
			'<SOURCE_DIR>/configure' \
				--build='{}' \
				--host='{}' \
				--target='${DJGPP_TARGET_TRIPLET}' \
				--prefix='${STAGE2_BINARY_DIR}' \
				--disable-multilib \
				--disable-nls \
				--disable-werror\
				\
				--disable-libstdcxx\
				--disable-libada\
				--disable-libgm2\
				--disable-libssp\
				--enable-year2038\
				--disable-libquadmath\
				--enable-host-pie\
				--enable-host-shared\
				--disable-plugins"
				
	BUILD_COMMAND
		${MAKE_EXE} "-j${NJOBS}"

	INSTALL_COMMAND
		${MAKE_EXE} "-j${NJOBS}" install-strip

	BUILD_BYPRODUCTS
		"${BINUTILS_STAGE2_BYPRODUCTS}"
)

add_custom_target(BINUTILS_Stage2_Ninja DEPENDS "${BINUTILS_STAGE2_BYPRODUCTS}")
add_dependencies(BINUTILS_Stage2_Ninja PTHREAD_Stage2_Ninja BINUTILS_Stage2)

# ex:set ts=2
