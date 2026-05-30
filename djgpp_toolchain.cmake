#
# Example CMake toolchain file for cross-compiling with DJGPP.
#
# Written in 2026 by Alexander Bruines <alexander.bruines@gmail.com>
# To the extent possible under law, the author has dedicated all copyright 
# and related rights to this file to the public domain worldwide. 
# This file is distributed without any warranty.
#

#
# Usage:
# cmake -DCMAKE_TOOLCHAIN_FILE=<this_file> [-DDJDPP_MARCH=i586] ...
#
# This script does not enable POSIX threads, if pthread is required use
# find_package(Threads REQUIRED GLOBAL) and set your target link libraries as
# target_link_libraries(target_name Threads::Threads) to include it.
# (This should automatically add the -pthread option to GCC.)
#

# This means that our toolchain is like that on Linux,
# ie. not that DJGPP is a Linux OS...
set(CMAKE_SYSTEM_NAME Linux)

# The DJGPP_MARCH variable is used to determine TARGET_TRIPLET (when that
# value is unset), and is set as CMAKE_SYSTEM_PROCESSOR.
# Note that using DJGPP_MARCH to set the gcc -march= parameter is left for the calling script.
if(NOT DEFINED DJGPP_MARCH)
	set(DJGPP_MARCH "i586" CACHE STRING "Default CMAKE_SYSTEM_PROCESSOR")
endif()
set(CMAKE_SYSTEM_PROCESSOR ${DJGPP_MARCH})

# Guessed from DJGPP_MARCH if not set on the commandline.
if(NOT DEFINED TARGET_TRIPLET)
	set(TARGET_TRIPLET "" CACHE STRING "Target system triplet.")
endif()
if( "${DJGPP_MARCH}" STREQUAL "i386" OR
		"${DJGPP_MARCH}" STREQUAL "i486" OR
		"${DJGPP_MARCH}" STREQUAL "i586" OR
		"${DJGPP_MARCH}" STREQUAL "i686" OR
		"${DJGPP_MARCH}" STREQUAL "i786")
	# DJGPP_MARCH is a compatible value, use it in the tgt triplet
	# if TARGET_TRIPLET is empty.
	if(NOT TARGET_TRIPLET)
		set(TARGET_TRIPLET "${DJGPP_MARCH}-pc-msdosdjgpp")
	endif()
else()
	if(NOT TARGET_TRIPLET)
		# DJGPP_MARCH is not a compatible value,
		# and TARGET_TRIPLET is empty. Assume i786.
		set(TARGET_TRIPLET "i786-pc-msdosdjgpp")
	endif()
endif()

# Allow EXEEXT to be set on the commandline but set its default to '.exe'.
if(NOT DEFINED EXEEXT)
	set(EXEEXT "" CACHE STRING "File-extension of executables.")
endif()
if(NOT EXEEXT)
	set(EXEEXT ".exe")
endif()

# And use it to define the TOOLCHAIN_PREFIX and derrive the BINUTILS_PATH.
set(TOOLCHAIN_PREFIX ${TARGET_TRIPLET}-)
execute_process(
	COMMAND which ${TOOLCHAIN_PREFIX}gcc
	OUTPUT_VARIABLE BINUTILS_PATH
	OUTPUT_STRIP_TRAILING_WHITESPACE)

# Now infer the DJGPP toolchain location.
get_filename_component(DJGPP_TOOLCHAIN_DIR ${BINUTILS_PATH} DIRECTORY)

# Setup the various compilers...
set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER})
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}g++)
set(CMAKE_Fortran_COMPILER ${TOOLCHAIN_PREFIX}gfortran)
set(CMAKE_COVERAGE_TOOL ${TOOLCHAIN_PREFIX}gcov)

set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
set(CMAKE_Fortran_COMPILER_WORKS 1)

# ..and the SYSROOT directory.
set(CMAKE_SYSROOT ${DJGPP_TOOLCHAIN_DIR}/../${TARGET_TRIPLET})
set(CMAKE_FIND_ROOT_PATH ${BINUTILS_PATH})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Do not compile with -fPIC (which is ignored for DJGPP).
set(CMAKE_POSITION_INDEPENDENT_CODE OFF)

# We prefer to (ie. must) use 'gcc -pthread' for POSIX threads.
set(THREADS_PREFER_PTHREAD_FLAG TRUE)

# Let CMake know that the file-extention for DOS executables is .EXE
set(CMAKE_EXECUTABLE_SUFFIX "${EXEEXT}")

# ex:set noexpandtab tabstop=2 shiftwidth=2
