#!/bin/sh

# fsb-abersoft11k.sh

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
# to a ZX Spectrum TAP file suitable for Abersoft Forth, after
# being fixed by the Afera library
# (http://programandala.net/en.program.afera.html) to accept
# 11264-byte RAM-disk files).
#
# For the 16-KiB RAM-disk files, as implemented by the
# correspondent Afera module, use <fsb-abersoft16k.sh> (ZX
# Spectrum 128 only); for the original system (without Afera)
# use <fsb-abersoft.sh>.

# ##############################################################
# Requirements

# fsb:
# 	<http://programandala.net/en.program.fsb.html>
# bin2code:
#   <http://metalbrain.speccy.org/link-eng.htm>.

# ##############################################################
# Usage

#   fsb-abersoft11k.sh filename.fsb

# ##############################################################
# History

# 2015-05-13: First version, forked from <fsb-abersoft.sh>
#
# 2015-09-11: Updated headers and layout.
#
# 2015-10-12: Updated after the renaming of the converter files.

# ##############################################################
# Error checking

if [ "$#" -ne 1 ] ; then
  echo "Convert a Forth source file from .fsb to .tap format for fixed Abersoft Forth"
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

head --bytes=11264 $blocksfile > DISC
  
# The bin2code converter uses the host system filename in the
# TAP file header (there's no option to change it) and Abersoft
# Forth needs the file in the tape to be called "DISC".  That's
# why an intermediate file called "DISC" is used.

bin2code DISC $tapefile
echo "\"$tapefile\" created"

# Remove the intermediate files:

rm -f DISC $blocksfile
	
# vim:tw=64:ts=2:sts=2:et:

