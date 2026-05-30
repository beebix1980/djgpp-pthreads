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

# Stage 2 / Package 4 : DJGPP cross-compiler (GCC, C only)

include(BINUTILS_Stage2)

set(GCC_STAGE2_BYPRODUCTS
	"${STAGE2_BINARY_DIR}/bin/${DJGPP_TARGET_TRIPLET}-gcc")

ExternalProject_Add(GCC_Stage2 DEPENDS BINUTILS_Stage2_Ninja
	PREFIX "${STAGE2_BINARY_DIR}"
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
			"Enter the Ninja: '${PTHREAD_STAGE2_BYPRODUCTS}'" &&

		# Patch
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc-14.2.0.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-max_ofile_alignment.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-limits.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-putwc.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc151-pth207.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/gcc152-ops-common.patch" &&

		# Make a backup of pthread.h
		${CMAKE_COMMAND} -E make_directory "<TMP_DIR>" &&
		${CMAKE_COMMAND} -E copy
			"${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/pthread.h"
			"<TMP_DIR>"

	CONFIGURE_COMMAND
		# Ninja: Ensure that stage 2 binutils/libc/libsocket/libpthread are installed before this point.
		${CMAKE_COMMAND} -E cmake_echo_color --green "Enter the Ninja: \
			${BINUTILS_STAGE2_BYPRODUCTS} ${DJLSR_STAGE2_BYPRODUCTS} \
			${PTHSOCK_STAGE2_BYPRODUCTS} ${PTHREAD_STAGE2_BYPRODUCTS}" &&

		# Configure
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		${SH_EXE} -c "'<SOURCE_DIR>/config.guess' | '${XARGS_EXE}' -I {} \
			'<SOURCE_DIR>/configure' \
				--prefix='${STAGE2_BINARY_DIR}' \
				--build='{}' \
				--host='{}'  \
				--target='${DJGPP_TARGET_TRIPLET}' \
				--enable-checking=release \
				--with-gcc-major-version-only \
				--with-cpu=${DJGPP_MARCH} \
				--with-tune=${DJGPP_MTUNE} \
				--with-pkgversion='DJGPP 2.05' \
				--enable-languages=c \
				--disable-libstdcxx \
				--disable-shared \
				--enable-threads \
				--disable-multilib \
				--disable-nls\
				--enable-year2038\
				--disable-libquadmath\
				--enable-host-pie\
				--enable-host-shared\
				--disable-multilib\
				--disable-plugins"

	# Temporarely modify pthread.h for compiling gcc:
	# When building gcc the thread-aware functions must always be used
	# and this is the easiest method to do it...
	BUILD_COMMAND
		# Restore pthread.h
		${CMAKE_COMMAND} -E copy
			"<TMP_DIR>/pthread.h"
			"${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/" &&

		# Modify pthread.h
	  ${SED_EXE} -i
	  	"s/defined(_REENTRANT)/1/"
	  	"${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/pthread.h" &&

	  # Build gcc
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
			${MAKE_EXE} "-j${NJOBS}" &&

		# Restore pthread.h
		${CMAKE_COMMAND} -E copy
			"<TMP_DIR>/pthread.h"
			"${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/"

	INSTALL_COMMAND
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		${MAKE_EXE} "-j${NJOBS}" install-strip

	BUILD_BYPRODUCTS
		"${GCC_STAGE2_BYPRODUCTS}"
)

add_custom_target(GCC_Stage2_Ninja DEPENDS "${GCC_STAGE2_BYPRODUCTS}")
add_dependencies(GCC_Stage2_Ninja BINUTILS_Stage2_Ninja GCC_Stage2)

set(STAGE2_BYPRODUCTS
	"${BINUTILS_STAGE2_BYPRODUCTS} ${DJLSR_STAGE2_BYPRODUCTS} \
	${PTHSOCK_STAGE2_BYPRODUCTS} ${PTHREAD_STAGE2_BYPRODUCTS} \
	${GCC_STAGE2_BYPRODUCTS}")

# ex:set ts=2
