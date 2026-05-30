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

# Stage 3 / Package 1 : Patched DJGPP runtime (based on DJLSR205)

include(GCC_Stage2)

# C_FLAGS used when compiling the DJGPP runtime (and WATT32).
# -fcommon is required
set(DJGPP_LIBC_OPTIMIZE_2 "
 -std=gnu99 -fcommon -O3 -fomit-frame-pointer -fno-fast-math -g3
 -falign-functions=64
 -falign-labels=16
")

# remove newlines
string(REPLACE "\n" "" DJGPP_LIBC_OPTIMIZE_2 ${DJGPP_LIBC_OPTIMIZE_2})

set(DJLSR_STAGE3_BYPRODUCTS
	"${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/lib/libc.a")

if(HAVE_WATT32)
	# Same as in stage 2, but for stage 3
	set(watt32_djlsr_patch_stage3
		&& ${CMAKE_COMMAND} -E make_directory "<SOURCE_DIR>/watt32/src/build/djgpp" &&
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		${PATCH_EXE} -d watt32 -p1 < "${PATCHES_DIRECTORY}/watt32s.patch" &&
		${PATCH_EXE} -d watt32 -p1 < "${PATCHES_DIRECTORY}/watt32s_stdbool.patch" &&
		${SED_EXE} -i "s/\\(.*BIN_PREFIX =\\)/\\1 ${DJGPP_TARGET_TRIPLET}-/" watt32/src/makefile.all &&
		${SED_EXE} -i "s/\\(-Wno-strict-aliasing\\)/${DJGPP_LIBC_OPTIMIZE_2} \\1/g" watt32/src/makefile.all &&
		${SH_EXE} -c
			"if ! [ -f include/sys/djcdefs.h ] $<SEMICOLON> then \
				rm -vf include/netinet/in.h && \
				rm -vf include/sys/errno.h && \
				mv -vf include/sys/cdefs.h include/sys/djcdefs.h && \
				mv -vf include/sys/ioctl.h include/sys/djioctl.h && \
				mv -vf include/sys/param.h include/sys/djparam.h && \
				cp -vfR watt32/inc/* include $<SEMICOLON>\
			fi && \
			if ! [ -f '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/sys/djcdefs.h' ] $<SEMICOLON> then \
				rm -vf '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/netinet/in.h' && \
				rm -vf '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/sys/errno.h' && \
				mv -vf '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/sys/cdefs.h' '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/sys/djcdefs.h' && \
				mv -vf '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/sys/ioctl.h' '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/sys/djioctl.h' && \
				mv -vf '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/sys/param.h' '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include/sys/djparam.h' && \
				cp -vfR watt32/inc/* '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/include' $<SEMICOLON>\
			fi" &&
		${CMAKE_COMMAND} -E copy "${PATCHES_DIRECTORY}/syserr.c" watt32/src/build/djgpp &&
		${SED_EXE} -i /include/d manifest/djcrx205.mft &&
		${SED_EXE} -i /include/d manifest/djdev205.mft &&
		${SH_EXE} -c "${FIND_EXE} include -type f >>manifest/djcrx205.mft" &&
		${SH_EXE} -c "${FIND_EXE} include -type f >>manifest/djdev205.mft")
else()
	set(watt32_djlsr_patch_stage3 "")
endif()

#
# This is the final build of the DJGPP runtime, and is compiled by a
# binutils/gcc which is in turn compiled using that exact same DJGPP runtime.
#
ExternalProject_Add(DJLSR_Stage3 DEPENDS GCC_Stage2_Ninja
	PREFIX "${STAGE3_BINARY_DIR}"
	USES_TERMINAL_DOWNLOAD TRUE
	USES_TERMINAL_PATCH TRUE
	USES_TERMINAL_BUILD TRUE
	USES_TERMINAL_INSTALL TRUE
	INSTALL_DIR "${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}"
	DOWNLOAD_DIR "${DOWNLOAD_DIRECTORY}"
	DOWNLOAD_EXTRACT_TIMESTAMP FALSE

	DOWNLOAD_COMMAND
		# Ensure directories exist.
		${CMAKE_COMMAND} -E rm -fr "<SOURCE_DIR>" &&
		${CMAKE_COMMAND}
			-E make_directory "<DOWNLOAD_DIR>" "<SOURCE_DIR>/watt32" &&

		# Download, verify and extract DJLSR.
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/${DJLSR_ZIP}"
			"-DHASH=${DJLSR_SHA256}"
			"-DDESTDIR=<SOURCE_DIR>"
			"-DARGS=-o"
			"-DURLS=${DJLSR_URL1}$<SEMICOLON>${DJLSR_URL2}$<SEMICOLON>${DJLSR_URL3}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadZIP.cmake" &&

		# Download, verify and extract DJDEV (do not overwrite files, cvt text files).
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/${DJDEV_ZIP}"
			"-DHASH=${DJDEV_SHA256}"
			"-DDESTDIR=<SOURCE_DIR>"
			"-DARGS=-o -n -a"
			"-DURLS=${DJDEV_URL1}$<SEMICOLON>${DJDEV_URL2}$<SEMICOLON>${DJDEV_URL3}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadZIP.cmake" &&

		# Download, verify and extract DJCRX (do not overwrite files, cvt text files).
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/${DJCRX_ZIP}"
			"-DHASH=${DJCRX_SHA256}"
			"-DDESTDIR=<SOURCE_DIR>"
			"-DARGS=-o -n -a"
			"-DURLS=${DJCRX_URL1}$<SEMICOLON>${DJCRX_URL2}$<SEMICOLON>${DJCRX_URL3}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadZIP.cmake" &&

		# Download, verify and extract DJTZS (do not overwrite files, cvt text files).
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/${DJTZS_ZIP}"
			"-DHASH=${DJTZS_SHA256}"
			"-DDESTDIR=<SOURCE_DIR>"
			"-DARGS=-o -n -a"
			"-DURLS=${DJTZS_URL1}$<SEMICOLON>${DJTZS_URL2}$<SEMICOLON>${DJTZS_URL3}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadZIP.cmake" &&

		# Download, verify and extract DJTZN (for the manifest files) (do not overwrite files, cvt text files).
		${CMAKE_COMMAND}
			"-DFILENAME=<DOWNLOAD_DIR>/${DJTZN_ZIP}"
			"-DHASH=${DJTZN_SHA256}"
			"-DDESTDIR=<SOURCE_DIR>"
			"-DARGS=-o -n -a"
			"-DURLS=${DJTZN_URL1}$<SEMICOLON>${DJTZN_URL2}$<SEMICOLON>${DJTZN_URL3}"
			"-P ${PROJECT_SOURCE_DIR}/cmake/DownloadZIP.cmake"

		# Download Watt32 if needed
		${watt32_djlsr_download}

	PATCH_COMMAND
		# Apply our patches
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc142-pthreads.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc142-required.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc142-optional.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-timespec.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc151-stdbool.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc151-infinity.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc151-sortsyms.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc151-dxe3gen.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc151-libm.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc151-texi2ps.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc152-npxsetup.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc152-go32.patch" &&
		${PATCH_EXE} -p1 < "${PATCHES_DIRECTORY}/djlsr205-gcc152-redir.patch" &&

		# Clean the build tree
		${MAKE_EXE} -C "<SOURCE_DIR>/src" clean &&
		${CMAKE_COMMAND} -E rm -f "<SOURCE_DIR>/lib/crt0.o" &&
		${CMAKE_COMMAND} -E rm -f "<SOURCE_DIR>/lib/gcrt0.o" &&
		${CMAKE_COMMAND} -E rm -f "<SOURCE_DIR>/lib/libc.a" &&
		${CMAKE_COMMAND} -E rm -f "<SOURCE_DIR>/lib/libdbg.a" &&
		#${CMAKE_COMMAND} -E rm -f "<SOURCE_DIR>/lib/libemu.a" &&
		${CMAKE_COMMAND} -E rm -f "<SOURCE_DIR>/lib/libg.a" &&
		${CMAKE_COMMAND} -E rm -f "<SOURCE_DIR>/lib/libm.a" &&
		${CMAKE_COMMAND} -E rm -f "<SOURCE_DIR>/lib/libpc.a" &&

		# Do not build the fpu emultor (when building libc with -flto),
		# just keep the pre-built one.
		${SED_EXE} -i "/libemu/d" "<SOURCE_DIR>/src/makefile" &&

		# Set -mtune/-march and other compilation flags
		${SED_EXE} -i "s/\\(-mcpu=\\)i586/\\1${DJGPP_MTUNE}/g" "<SOURCE_DIR>/src/makefile.cfg" &&
		${SED_EXE} -i "s/\\(-mtune=\\)i586/\\1${DJGPP_MTUNE}/g" "<SOURCE_DIR>/src/makefile.cfg" &&
		${SED_EXE} -i "s/\\(-march=\\)i386/\\1${DJGPP_MARCH}/g" "<SOURCE_DIR>/src/makefile.cfg" &&
		${SED_EXE} -i "s/-O2/${DJGPP_LIBC_OPTIMIZE_2}/g" "<SOURCE_DIR>/src/makefile.cfg" &&

		# Use the correct triplet for the flavour being build.
		${SED_EXE} -i "s/i586-pc-msdosdjgpp/${DJGPP_TARGET_TRIPLET}/g" "<SOURCE_DIR>/src/makefile.def"

		# WATT32 requires some more patching...
		${watt32_djlsr_patch_stage3}

	# No configuration step
	CONFIGURE_COMMAND ""

	# Rebuild the DJGPP v2.05 distro files.
	# Must use -j1 here, makefile does not support parallel jobs!
	# (WATT32 is build later by PTHSOCK_Stage3 if selected.)
	BUILD_COMMAND
		# Ninja: Ensure that stage 2 binaries are installed before this point.
		${CMAKE_COMMAND} -E cmake_echo_color --green
			"Enter the Ninja: ${STAGE2_BYPRODUCTS}" &&

		# Build
		#${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		#${MAKE_EXE} -C "<SOURCE_DIR>/src" -j1
		#
		# Instead of the above, compile the 'all' target in steps so we can
		# spread it over multiple jobs where possible.
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		${MAKE_EXE} -C "<SOURCE_DIR>/src" -j1 "misc.exe" "config" "../hostbin"
			"../bin" "../include" "../info" "../lib" "makemake.exe" &&
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		${MAKE_EXE} -C "<SOURCE_DIR>/src" "-j${NJOBS}" "subs" &&
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		${MAKE_EXE} -C "<SOURCE_DIR>/src" -j1 "../lib/libg.a" "../lib/libpc.a" &&

		# Rebuild DJGPP distro files.
		${SH_EXE} -c "\
			cd '<SOURCE_DIR>' &&\
			'${ZIP_EXE}' -q \
				-@ '${CMAKE_CURRENT_BINARY_DIR}/djcrx205-stage3.zip'\
				< 'manifest/djcrx205.mft' &&\
			'${ZIP_EXE}' -q \
				-@ '${CMAKE_CURRENT_BINARY_DIR}/djdev205-stage3.zip'\
				< 'manifest/djdev205.mft' &&\
			'${ZIP_EXE}' -q \
				-@ '${CMAKE_CURRENT_BINARY_DIR}/djlsr205-stage3.zip'\
				< 'manifest/djlsr205.mft' &&\
			'${ZIP_EXE}' -q \
				-@ '${CMAKE_CURRENT_BINARY_DIR}/djtzs205-stage3.zip'\
				< 'manifest/djtzs205.mft' &&\
			'${ZIP_EXE}' -q \
				-@ '${CMAKE_CURRENT_BINARY_DIR}/djtzn205-stage3.zip'\
				< 'manifest/djtzn205.mft'"

	# Install into the stage3 prefix.
	INSTALL_COMMAND
		# Ensure that these dirctories exist.
		${CMAKE_COMMAND} -E make_directory
			"<INSTALL_DIR>/${DJGPP_TARGET_TRIPLET}"
			"<INSTALL_DIR>/bin" &&

		# Unzip the rebuilt DJCRX to the binaries directory
		${UNZIP_EXE} -q
			-o "${CMAKE_CURRENT_BINARY_DIR}/djcrx205-stage3.zip"
			-d "<INSTALL_DIR>/${DJGPP_TARGET_TRIPLET}" &&

		# Install tools for the host
		${CMAKE_COMMAND} -E copy
			"<SOURCE_DIR>/hostbin/bin2h.exe" "<INSTALL_DIR>/bin/bin2h" &&
		${CMAKE_COMMAND} -E copy
			"<SOURCE_DIR>/hostbin/djasm.exe" "<INSTALL_DIR>/bin/djasm" &&
		${CMAKE_COMMAND} -E copy
			"<SOURCE_DIR>/hostbin/dxegen.exe" "<INSTALL_DIR>/bin/dxegen" &&
		${CMAKE_COMMAND} -E copy
			"<SOURCE_DIR>/hostbin/stubedit.exe" "<INSTALL_DIR>/bin/stubedit" &&
		${CMAKE_COMMAND} -E copy
			"<SOURCE_DIR>/hostbin/stubify.exe" "<INSTALL_DIR>/bin/stubify" &&
		${CMAKE_C_COMPILER} -O3 -Xlinker --strip-all -DNDEBUG
			-o "<INSTALL_DIR>/bin/dtou" "<SOURCE_DIR>/src/utils/dtou.c" &&
		${CMAKE_C_COMPILER} -O3 -Xlinker --strip-all -DNDEBUG
			-o "<INSTALL_DIR>/bin/utod" "<SOURCE_DIR>/src/utils/utod.c"

	BUILD_BYPRODUCTS
		"${DJLSR_STAGE3_BYPRODUCTS}"
)

add_custom_target(DJLSR_Stage3_Ninja DEPENDS "${DJLSR_STAGE3_BYPRODUCTS}")
add_dependencies(DJLSR_Stage3_Ninja GCC_Stage2_Ninja DJLSR_Stage3)

# ex:set ts=2
