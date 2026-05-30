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

# Stage 1 / Package 2 : DJGPP runtime (DJCRX205)

include(BINUTILS_Stage1)

set(DJCRX_STAGE1_BYPRODUCTS
	"${STAGE1_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/lib/libc.a")

# This target downloads and installs the standard DJGPP cross-compiler
# runtime (DJCRX205.ZIP). We will use it to build our stage 1 toolchain.
ExternalProject_Add(DJCRX_Stage1 DEPENDS BINUTILS_Stage1_Ninja
	PREFIX "${STAGE1_BINARY_DIR}"
	DOWNLOAD_DIR "${DOWNLOAD_DIRECTORY}"
	SOURCE_SUBDIR "djcrx"

	DOWNLOAD_COMMAND
		# Ensure directories exist.
		${CMAKE_COMMAND} -E rm -fr "<SOURCE_DIR>" &&
		${CMAKE_COMMAND} -E make_directory "<SOURCE_DIR>" "<DOWNLOAD_DIR>" &&

		# Download, verify and extract DJCRX source archive.
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/${DJCRX_ZIP}"
			"-DHASH=${DJCRX_SHA256}"
			"-DDESTDIR=<SOURCE_DIR>"
			"-DARGS=-o"
			"-DURLS=${DJCRX_URL1}$<SEMICOLON>${DJCRX_URL2}$<SEMICOLON>${DJCRX_URL3}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadZIP.cmake"

	# No configure or build step...
	CONFIGURE_COMMAND ""
	BUILD_COMMAND ""

	# Install to STAGE1_BINARY_DIR
	INSTALL_COMMAND
		${CMAKE_COMMAND} -E make_directory
			"<INSTALL_DIR>/bin" "<INSTALL_DIR>/${DJGPP_TARGET_TRIPLET}" &&
		${CMAKE_COMMAND} -E copy_directory
			"<SOURCE_DIR>/include" "<INSTALL_DIR>/${DJGPP_TARGET_TRIPLET}/include" &&
		${CMAKE_COMMAND} -E copy_directory
			"<SOURCE_DIR>/lib" "<INSTALL_DIR>/${DJGPP_TARGET_TRIPLET}/lib" &&
		${CMAKE_C_COMPILER} -O3 -Xlinker --strip-all -DNDEBUG
			"<SOURCE_DIR>/src/stub/stubify.c" -o "<INSTALL_DIR>/bin/stubify${CMAKE_EXECUTABLE_SUFFIX}" &&
		${CMAKE_C_COMPILER} -O3 -Xlinker --strip-all -DNDEBUG
			"<SOURCE_DIR>/src/stub/stubedit.c" -o "<INSTALL_DIR>/bin/stubedit${CMAKE_EXECUTABLE_SUFFIX}"

	BUILD_BYPRODUCTS
		"${DJCRX_STAGE1_BYPRODUCTS}"
)

add_custom_target(DJCRX_Stage1_Ninja DEPENDS "${DJCRX_STAGE1_BYPRODUCTS}")
add_dependencies(DJCRX_Stage1_Ninja BINUTILS_Stage1_Ninja DJCRX_Stage1)

# ex:set ts=2
