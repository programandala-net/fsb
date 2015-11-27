#!/bin/sh

# fsb-fb.sh

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
# to a Forth blocks file.

# ##############################################################
# Usage

#   fsb-fb.sh filename.fsb

# ##############################################################
# History

# 2015-03-10: First version.
#
# 2015-03-16: '-R' option instead of '-n'; this prevents the
# warning "the file was modified" when the file is being edited.
#
# Directory removed from <fsb.vim>, in order to be installed in
# any directory in Vim's 'runtimepath'.
#
# This change causes error 484, "fsb.vim" can not be open.  But
# the task is done!
#
# 2015-03-19: Fix: 'runtime' instead of '-S'.
#
# 2015-03-22: Improved error messages.
#
# 2015-03-23: No error when the source is empty any more: 1
# empty block will be created by the converter.
#
# 2015-09-11: Updated headers and layout.
#
# 2015-10-12: Updated after the renaming of the converter files.

# ##############################################################
# Error checking

if [ "$#" -ne 1 ] ; then
  echo "Convert a Forth source file from .fsb to .fb format"
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

# XXX OLD
# if [ ! -s "$1"  ] ; then
#   echo "Error: <$1> is empty"
#   exit 1
# fi

# ##############################################################
# Main

# Vim options:
# -e = Enter Vim in ex mode (in this case, the goal is just
#      preventing Vim from clearing the screen).
# -n = No swap file will be used. This makes it possible
#      to convert a file currently open by other instance of Vim,
#      without the user to be asked for confirmation.
# -R = read-only mode (implies -n).
# -s = Silent mode (does not affect BAS2TAP messages).
# -S = Vim file to be sourced after the first file has been read.
# -c = Vim command to be executed after the first file has been read.

#vim -e -R -S fsb.vim -c "call Fsb2fb() | qall!" $1
vim -e -R -c "runtime fsb.vim | call Fsb2fb() | qall!" $1
#echo about to call Vim
#vim -e -R -c "call Fsb2fb() | qall!" $1
#echo Vim finished
exit $?

# vim:tw=64:ts=2:sts=2:et:

