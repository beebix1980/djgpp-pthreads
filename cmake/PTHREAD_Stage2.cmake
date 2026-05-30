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

# Stage 2 / Package 3 : pthread library (PTH207S)

include(PTHSOCK_Stage2)

# The source directory in the source tarball
set(PTHREAD_SUBDIR  "src/pth-2.0.7")

# The CFLAGS used when building GNU Pth
# -mtune and -march are set during CONFIGURE_COMMAND!
set(PTHREAD_C_FLAGS_1 "
 -std=gnu99 -fcommon -O2 -fomit-frame-pointer -ffast-math -g3
 -falign-functions=64
 -falign-labels=16
")

# remove newlines
string(REPLACE "\n" "" PTHREAD_C_FLAGS_1 ${PTHREAD_C_FLAGS_1})

set(PTHREAD_STAGE2_BYPRODUCTS
	"${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/pthread.h")

ExternalProject_Add(PTHREAD_Stage2 DEPENDS PTHSOCK_Stage2_Ninja
	PREFIX "${STAGE2_BINARY_DIR}"
	USES_TERMINAL_DOWNLOAD TRUE
	USES_TERMINAL_CONFIGURE TRUE
	USES_TERMINAL_BUILD TRUE
	USES_TERMINAL_INSTALL TRUE
	DOWNLOAD_DIR "${DOWNLOAD_DIRECTORY}"
	SOURCE_SUBDIR "${PTHREAD_SUBDIR}"

	DOWNLOAD_COMMAND
		# Ensure directories exist
		${CMAKE_COMMAND} -E rm -fr "<SOURCE_DIR>" &&
		${CMAKE_COMMAND} -E make_directory "<SOURCE_DIR>" "<DOWNLOAD_DIR>" &&

		# Download, verify and extract
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/${PTHREAD_ZIP}"
			"-DHASH=${PTHREAD_HASH}"
			"-DDESTDIR=<SOURCE_DIR>"
			"-DARGS=-q -a -o"
			"-DURLS=${PTHREAD_URL1}$<SEMICOLON>${PTHREAD_URL2}$<SEMICOLON>${PTHREAD_URL3}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadZIP.cmake" &&

		# Update config.guess and config.sub
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/config.guess"
			"-DURL=${CONFIG_GUESS_URL}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadFile.cmake" &&
		${CMAKE_COMMAND}
			-E copy "<DOWNLOAD_DIR>/config.guess" "<SOURCE_DIR><SOURCE_SUBDIR>" &&
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/config.sub"
			"-DURL=${CONFIG_SUB_URL}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadFile.cmake" &&
		${CMAKE_COMMAND}
			-E copy "<DOWNLOAD_DIR>/config.sub" "<SOURCE_DIR><SOURCE_SUBDIR>" &&

		# shtool must be executable
		${SH_EXE} -c
			"cd '<SOURCE_DIR><SOURCE_SUBDIR>' && \
			chmod +x ./configure ./config.guess ./config.sub ./shtool"

	# Patches:
	# A: Only use the thread aware libc replacement functions when -pthread
	#    was passed to gcc, ie. when _REENTRANT is defined.
	# B: __STRICT_ANSI__ prevents the declaration of signal_t, sigset_t and off_t
	#    (use -std=gnu... instead of -std=c... if they're needed).
	#    Add a #ifndef __STRICT_ANSI__ clause to pthread.h where appropriate.
	PATCH_COMMAND
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/pth207s.patch" &&
		${SED_EXE} -i "s/cross_compiling=no/cross_compiling=yes/g" "<SOURCE_DIR><SOURCE_SUBDIR>/configure"

	CONFIGURE_COMMAND
		# Ninja: Ensure that stage 1 binaries and stage 2 libsocket are installed before this point.
		${CMAKE_COMMAND} -E cmake_echo_color --green
			"Enter the Ninja: ${STAGE1_BYPRODUCTS} ${PTHSOCK_STAGE2_BYPRODUCTS}" &&

		# Configure
		${CMAKE_COMMAND} -E env "PATH=${STAGE1_BINARY_DIR}/bin:$ENV{PATH}" --
			${SH_EXE} -c "\
				'<SOURCE_DIR><SOURCE_SUBDIR>/config.guess' | '${XARGS_EXE}' -I {} \
					'<SOURCE_DIR><SOURCE_SUBDIR>/configure' \
						--prefix='${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}' \
						--build='{}' \
						--host='${DJGPP_TARGET_TRIPLET}' \
						--target='${DJGPP_TARGET_TRIPLET}' \
						--enable-subdir \
						--enable-optimize \
						--enable-static \
						--disable-shared \
						--enable-pthread \
						--with-pipe=disable \
						--with-mctx-mth=sjlj \
						--with-mctx-dsp=sjljlx \
						--disable-tests" &&

		# Modify CFLAGS before building
		${SED_EXE} -i
			"s|\\(CFLAGS.*=\\).*|\\1 -I<SOURCE_DIR><SOURCE_SUBDIR> -D_REENTRANT -mtune=${DJGPP_MTUNE} -march=${DJGPP_MARCH} ${PTHREAD_C_FLAGS_1}|"
			"Makefile"

	# Build (very old makefiles) using a single job.
	BUILD_COMMAND
		${CMAKE_COMMAND} -E env "PATH=${STAGE1_BINARY_DIR}/bin:$ENV{PATH}" --
		${MAKE_EXE} -j1

	# Install to STAGE2_BINARY_DIR
	INSTALL_COMMAND
		${CMAKE_COMMAND} -E env "PATH=${STAGE1_BINARY_DIR}/bin:$ENV{PATH}" --
		${MAKE_EXE} install

	BUILD_BYPRODUCTS
		"${PTHREAD_STAGE2_BYPRODUCTS}"
)

add_custom_target(PTHREAD_Stage2_Ninja DEPENDS "${PTHREAD_STAGE2_BYPRODUCTS}")
add_dependencies(PTHREAD_Stage2_Ninja PTHSOCK_Stage2_Ninja PTHREAD_Stage2)

# ex:set ts=2
