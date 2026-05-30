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

# Stage 1 / Package 3 : DJGPP cross-compiler (GCC, C only)

include(DJCRX_Stage1)

set(GCC_STAGE1_BYPRODUCTS "${STAGE1_BINARY_DIR}/bin/${DJGPP_TARGET_TRIPLET}-gcc")

# This target builds gcc for our stage 1 toolchain. It is configured for the
# C language only since thats all we will need to build the stage 2 toolchain.
ExternalProject_Add(GCC_Stage1 DEPENDS DJCRX_Stage1_Ninja
	PREFIX "${STAGE1_BINARY_DIR}"
	USES_TERMINAL_DOWNLOAD TRUE
	USES_TERMINAL_CONFIGURE TRUE
	USES_TERMINAL_BUILD TRUE
	USES_TERMINAL_INSTALL TRUE
	DOWNLOAD_DIR "${DOWNLOAD_DIRECTORY}"
	DOWNLOAD_EXTRACT_TIMESTAMP FALSE
	URL	${GCC_URL}
	URL_HASH ${GCC_HASH}

	PATCH_COMMAND
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc-14.2.0.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-max_ofile_alignment.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-limits.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-putwc.patch"

	CONFIGURE_COMMAND
		# Ninja: Ensure that binutils and djcrx are built before configuring gcc.
		${CMAKE_COMMAND} -E cmake_echo_color --green "Enter the Ninja: "
			"${BINUTILS_STAGE1_BYPRODUCTS} ${DJCRX_STAGE1_BYPRODUCTS}" &&

		# Configure
		${CMAKE_COMMAND} -E env "PATH=${STAGE1_BINARY_DIR}/bin:$ENV{PATH}" --
			${SH_EXE} -c "'<SOURCE_DIR>/config.guess' | '${XARGS_EXE}' -I {} \
				'<SOURCE_DIR>/configure' \
					--prefix='${STAGE1_BINARY_DIR}' \
					--build='{}' \
					--host='{}' \
					--target='${DJGPP_TARGET_TRIPLET}' \
					--enable-checking=release \
					--with-gcc-major-version-only \
					--with-cpu=${DJGPP_MARCH} \
					--with-tune=${DJGPP_MTUNE} \
					--with-pkgversion='DJGPP 2.05' \
					--enable-languages=c \
					--disable-libstdcxx \
					--disable-shared \
					--disable-threads \
					--disable-multilib \
					--disable-nls \
					--enable-year2038 \
					--disable-libquadmath \
					--enable-host-pie \
					--enable-host-shared"

	BUILD_COMMAND
		${CMAKE_COMMAND} -E env "PATH=${STAGE1_BINARY_DIR}/bin:$ENV{PATH}" --
		${MAKE_EXE} "-j${NJOBS}"

	INSTALL_COMMAND
		${CMAKE_COMMAND} -E env "PATH=${STAGE1_BINARY_DIR}/bin:$ENV{PATH}" --
		${MAKE_EXE} "-j${NJOBS}" install-strip

	BUILD_BYPRODUCTS
		"${GCC_STAGE1_BYPRODUCTS}"
)

add_custom_target(GCC_Stage1_Ninja DEPENDS "${GCC_STAGE1_BYPRODUCTS}")
add_dependencies(GCC_Stage1_Ninja DJCRX_Stage1_Ninja GCC_Stage1)

set(STAGE1_BYPRODUCTS
	"${BINUTILS_STAGE1_BYPRODUCTS} ${DJCRX_STAGE1_BYPRODUCTS}"
	"${GCC_STAGE1_BYPRODUCTS}")

# ex:set ts=2
