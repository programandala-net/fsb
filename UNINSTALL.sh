#!/bin/sh

# UNINSTALL.sh

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

# This program uninstalls fsb.
#
# Edit <CONFIG.sh> first to suit your system.

# ##############################################################
# Usage

#   UNINSTALL.sh

# ##############################################################
# History

# 2015-10-12: First version.

# ##############################################################

. ./CONFIG.sh

rm -f $VIMDIR/fsb.vim
rm -f $VIMDIR/ftdetect/fsb.vim

rm -f $BINDIR/fsb-abersoft11k
rm -f $BINDIR/fsb-abersoft16k
rm -f $BINDIR/fsb-abersoft
rm -f $BINDIR/fsb-fb
rm -f $BINDIR/fsb-fbs
rm -f $BINDIR/fsb-mgt
rm -f $BINDIR/fsb-tap
