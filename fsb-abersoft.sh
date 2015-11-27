#!/bin/sh

# fsb-abersoft.sh

# This file is part of fsb
# http://programandala.net/en.program.fsb.html

# ##############################################################
# Author and license

# Copyright (C) 2015 Marcos Cruz (programandala.net)

# You may do whatever you want with this work, so long as you
# retain the copyright notice(s) and this license in all
# redistributed copies and derived works. There is no warranty.

# ##############################################################
# Description

# This program converts a Forth source file from the FSB format
# to a ZX Spectrum TAP file suitable for Abersoft Forth.
#
# Abersoft Forth has a bug: the last byte of its RAM-disk (11
# blocks of 1 KiB) is not saved to tape (11263 bytes are saved
# instead of 11264). Trying to load a complete 11264-byte
# RAM-disk file causes "Tape loading error". The solution is to
# remove the last byte from the file.
#
# For Abersoft Forth systems with the Afera library
# (http://programandala.net/en.program.afera.html) use
# <fsb-abersoft11k.sh> or <fsb-abersoft16k.sh> instead.

# ##############################################################
# Requirements

# fsb:
# 	<http://programandala.net/en.program.fsb.html>
# bin2code:
#   <http://metalbrain.speccy.org/link-eng.htm>.

# ##############################################################
# Usage

#   fsb-abersoft.sh filename.fsb

# ##############################################################
# History

# 2015-03-13: First version.
#
# 2015-03-15: Improved comments.
#
# 2015-03-16: Also the .fb blocks file is removed at the end.
#
# 2015-03-22: Improved error messages; the length of the blocks
# file is checked.
#
# 2015-03-27: File length is configurable, depending on the
# status of the Forth system: original (with the bug) or
# hacked/fixed.
#
# 2015-09-11: Updated headers and layout. Removed the old unused
# configurable code, since <fsb-abersoft11k.sh> and
# <fsb-abersoft16k.sh> are used instead.
#
# 2015-10-12: Updated after the renaming of the converter files.

# ##############################################################
# Error checking

if [ "$#" -ne 1 ] ; then
  echo "Convert a Forth source file from .fsb to .tap format for Abersoft Forth"
  echo 'Usage:'
  echo "  ${0##*/} sourcefile.fsb"
  exit 1
fi

if [ ! -e "$1"  ] ; then
  echo "Error: <$1> does not exist"
  exit 1
fi

if [ ! -f "$1"  ] ; then
  echo "Error: <$1> is not a regular file"
  exit 1
fi

if [ ! -r "$1"  ] ; then
  echo "Error: <$1> can not be read"
  exit 1
fi

if [ ! -s "$1"  ] ; then
  echo "Error: <$1> is empty"
  exit 1
fi

# ##############################################################
# Main

fsb-fb $1

# Get the filenames:

basefilename=${1%.*}
blocksfile=$basefilename.fb
tapefile=$basefilename.tap

# Create the target file:

head --bytes=11263 $blocksfile > DISC
  
# The bin2code converter uses the host system filename in the
# TAP file header (there's no option to change it) and Abersoft
# Forth needs the file in the tape to be called "DISC".  That's
# why an intermediate file called "DISC" is used.

bin2code DISC $tapefile
echo "\"$tapefile\" created"

# Remove the intermediate files:

rm -f DISC $blocksfile
	
# vim:tw=64:ts=2:sts=2:et:
