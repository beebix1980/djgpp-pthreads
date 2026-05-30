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

#
# CMake script to download a file from a (ExternalProject_Add) command.
# Run with:
#
#		${CMAKE_COMMAND}
#			"-DFILENAME=/path/to/and/filename"
#			"-DURL=url
#			"-P /path/to/Download.cmake"
#

function(simple_download filename url)
	file(DOWNLOAD "${url}" "${filename}" STATUS status SHOW_PROGRESS)
	list(GET status 0 result)
	list(GET status 1 reason)
	if(result EQUAL 0)
		message(STATUS "${reason}")
		return()
	endif()
	message(FATAL_ERROR "\nFailed to download ${filename} from ${url} (${reason})\n")
endfunction()

if(EXISTS "${FILENAME}")
	file(SIZE "${FILENAME}" _file_size)
	if(_file_size GREATER 0)
		message(STATUS "File already exists and is non-empty: ${FILENAME} (skipping download)")
		return()
	endif()
endif()

simple_download("${FILENAME}" "${URL}")

# ex:set ts=2
