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

# Stage 3 / Package 2 : Sockets library (dummy or WATT32)

include(DJLSR_Stage3)

set(PTHSOCK_STAGE3_BYPRODUCTS
	"${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/lib/libsocket.a")

if(HAVE_WATT32)
# Using WATT32 as sockets library...

ExternalProject_Get_property(DJLSR_Stage3 SOURCE_DIR)
set(WATT32_SRC "${SOURCE_DIR}/watt32")

ExternalProject_Add(PTHSOCK_Stage3 DEPENDS DJLSR_Stage3_Ninja
	PREFIX "${STAGE3_BINARY_DIR}"
	USES_TERMINAL_DOWNLOAD TRUE
	USES_TERMINAL_CONFIGURE TRUE
	USES_TERMINAL_BUILD TRUE
	USES_TERMINAL_INSTALL TRUE
	DOWNLOAD_COMMAND ""

	CONFIGURE_COMMAND
		${CMAKE_COMMAND} -E cmake_echo_color --green
			"Enter the Ninja: ${STAGE2_BYPRODUCTS} '${DJLSR_STAGE3_BYPRODUCTS}'" &&
		${CMAKE_COMMAND} -E env
			"PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}"
			"WATT_ROOT='${WATT32_SRC}'" --
		${SH_EXE} -c "\
			cd '${WATT32_SRC}/src' && \
				'${SH_EXE}' ./configur.sh djgpp && \
					../util/linux/mkmake makefile.all \
						-odjgpp.mak -dbuild/djgpp DJGPP DJGPP FLAT RELEASE"

	BUILD_COMMAND
		${CMAKE_COMMAND} -E env
			"PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}"
			"WATT_ROOT='${WATT32_SRC}'"
			"W32_NASM_='${NASM_EXE}'"
			"W32_BIN2C_=../util/linux/bin2c" --
				${MAKE_EXE} -j1 -C "${WATT32_SRC}/src" -f "${WATT32_SRC}/src/djgpp.mak"

	INSTALL_COMMAND
		${SH_EXE} -c "\
			cp -vf '${WATT32_SRC}/lib/libwatt.a' '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/lib' &&\
			cp -vf '${WATT32_SRC}/lib/libwatt.a' '${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/lib' &&\
			cd '${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}/lib' && ln -vfs libwatt.a libsocket.a &&\
			cd '${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}/lib' && ln -vfs libwatt.a libsocket.a"

	BUILD_BYPRODUCTS "${PTHSOCK_STAGE3_BYPRODUCTS}"
)

else()
# Using the dummy sockets library...

ExternalProject_Add(PTHSOCK_Stage3 DEPENDS DJLSR_Stage3_Ninja
	PREFIX "${STAGE3_BINARY_DIR}"
	USES_TERMINAL_DOWNLOAD TRUE
	USES_TERMINAL_CONFIGURE TRUE
	USES_TERMINAL_BUILD TRUE
	USES_TERMINAL_INSTALL TRUE
	URL "${PTHSOCK_URL}"
	URL_HASH "${PTHSOCK_HASH}"
	DOWNLOAD_EXTRACT_TIMESTAMP FALSE

	CONFIGURE_COMMAND
		# Ninja: Ensure that stage 2 binaries are installed before this point.
		${CMAKE_COMMAND} -E cmake_echo_color --green
			"Enter the Ninja: ${STAGE2_BYPRODUCTS}" &&

		# Configure
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		${CMAKE_COMMAND}
			"-G ${CMAKE_GENERATOR}"
			"-S <SOURCE_DIR>"
			"-B <BINARY_DIR>"
			"-DDJGPP_MARCH=${DJGPP_MARCH}"
			"-DCMAKE_INSTALL_PREFIX=${DJGPP_TARGET_TRIPLET}"
			"-DCMAKE_TOOLCHAIN_FILE=${PROJECT_SOURCE_DIR}/djgpp_toolchain.cmake"

	BUILD_COMMAND
		${CMAKE_COMMAND} -E env "PATH=${STAGE2_BINARY_DIR}/bin:$ENV{PATH}" --
		${CMAKE_COMMAND} --build "<BINARY_DIR>"

	INSTALL_COMMAND
		${CMAKE_COMMAND}
			--install "<BINARY_DIR>"
			--prefix "${STAGE2_BINARY_DIR}/${DJGPP_TARGET_TRIPLET}" &&
		${CMAKE_COMMAND}
			--install "<BINARY_DIR>"
			--prefix "${STAGE3_BINARY_DIR}/${CMAKE_INSTALL_PREFIX}/${DJGPP_TARGET_TRIPLET}"

	BUILD_BYPRODUCTS
		"${PTHSOCK_STAGE3_BYPRODUCTS}"
)

endif()

add_custom_target(PTHSOCK_Stage3_Ninja DEPENDS "${PTHSOCK_STAGE3_BYPRODUCTS}")
add_dependencies(PTHSOCK_Stage3_Ninja DJLSR_Stage3_Ninja PTHSOCK_Stage3)

# ex:set ts=2
