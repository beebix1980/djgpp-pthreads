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

# Stage 1 / Package 1 : BINUTILS configured for DJGPP

set(BINUTILS_STAGE1_BYPRODUCTS
	"${STAGE1_BINARY_DIR}/bin/${DJGPP_TARGET_TRIPLET}-ld")

# This target builds binutils for our stage 1 toolchain.
ExternalProject_Add(BINUTILS_Stage1
	PREFIX "${STAGE1_BINARY_DIR}"
	USES_TERMINAL_DOWNLOAD TRUE
	USES_TERMINAL_CONFIGURE TRUE
	USES_TERMINAL_BUILD TRUE
	USES_TERMINAL_INSTALL TRUE
	DOWNLOAD_DIR "${DOWNLOAD_DIRECTORY}"
	DOWNLOAD_EXTRACT_TIMESTAMP FALSE
	URL ${BNU_URL}
	URL_HASH ${BNU_HASH}

	# Apply patch to increase segment aligment to 64 bytes.
	PATCH_COMMAND
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/bnu244-coff_section_alignment.patch"

	CONFIGURE_COMMAND
		${SH_EXE} -c "'<SOURCE_DIR>/config.guess' | '${XARGS_EXE}' -I {} \
			'<SOURCE_DIR>/configure' \
				--build='{}' \
				--host='{}'  \
				--target='${DJGPP_TARGET_TRIPLET}' \
				--prefix='${STAGE1_BINARY_DIR}' \
				--disable-multilib \
				--disable-nls \
				--disable-werror\
				--disable-libstdcxx\
				--disable-libada\
				--disable-libgm2\
				--disable-libssp\
				--enable-year2038\
				--disable-libquadmath\
				--enable-host-pie\
				--enable-host-shared"

	BUILD_COMMAND
		${MAKE_EXE} "-j${NJOBS}"

	INSTALL_COMMAND
		${MAKE_EXE} "-j${NJOBS}" install-strip

	BUILD_BYPRODUCTS
		"${BINUTILS_STAGE1_BYPRODUCTS}"
)

add_custom_target(BINUTILS_Stage1_Ninja
	DEPENDS "${BINUTILS_STAGE1_BYPRODUCTS}")

add_dependencies(BINUTILS_Stage1_Ninja BINUTILS_Stage1)

# ex:set ts=2
