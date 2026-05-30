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
# CMake script to download, verify and extract ZIP archives.
# Run with:
#
#		${CMAKE_COMMAND}
#			"-DFILENAME=/path/to/and/filename"
#			"-DHASH=<method=hash>"
#			"-DDESTDIR=/dir/where/to/store"
#			"-DARGS=extra unzip args"           <--- optional
#			"-DURLS=url;url;url;..."            <--- one or more URL (list)
#			"-P /path/to/DownloadZIP.cmake"
#

find_program(SH_EXE sh REQUIRED)
find_program(UNZIP_EXE unzip REQUIRED)

# Function: Download a file using a list of alternative URLs
# urls == list of URLs
# filename == download path and filename to store the archive
# hash == expected SHA256
function(download_with_fallback filename hash urls)
	foreach(url IN LISTS urls)
		message(STATUS "Trying: ${url}")
		file(
			DOWNLOAD "${url}" "${filename}"
			STATUS status
			EXPECTED_HASH ${hash}
			SHOW_PROGRESS)
		list(GET status 0 result)
		list(GET status 1 reason)
		if(result EQUAL 0)
			message(STATUS "${reason}")
			return()
		else()
			message(WARNING "${reason}")
		endif()
	endforeach()
	message(FATAL_ERROR "\nFailed to download ${filename} from any provided URL!\n")
endfunction()

# Function: Download, verify and extract a ZIP archive.
# urls == list of URLs
# filename == download path and filename to store the archive
# hash == expected SHA256
# destination == where to extract to (must exist)
# unzip_args == options to pass to UNZIP_EXE (or an empty string)
function(download_and_extract_zip filename hash destination unzip_args urls)
	download_with_fallback(${filename} ${hash} ${urls})
	message(STATUS "Extracting: ${filename}")
	execute_process(
		WORKING_DIRECTORY ${destination}
		COMMAND ${SH_EXE} -c "'${UNZIP_EXE}' ${unzip_args} ${filename}"
		RESULT_VARIABLE _r)
	if(NOT _r EQUAL 0)
		message(FATAL_ERROR "\nFailed to extract ${filename} to ${destination}!\n")
	endif()
endfunction()

download_and_extract_zip(
	"${FILENAME}" "${HASH}" "${DESTDIR}" "${ARGS}" "${URLS}")

# ex:set ts=2
