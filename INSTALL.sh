#!/bin/sh

# INSTALL.sh

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

# This program installs fsb.
#
# Edit <CONFIG.sh> first to suit your system.

# ##############################################################
# Usage

#   INSTALL.sh

# ##############################################################
# History

# 2015-10-12: First version.
# 2015-12-29: SuperForth converter.

# ##############################################################

. ./CONFIG.sh

eval ${INSTALLCMD}fsb.converter.vim $VIMDIR/fsb.vim
eval ${INSTALLCMD}fsb.ftdetect.vim $VIMDIR/ftdetect/fsb.vim

eval ${INSTALLCMD}fsb-abersoft11k.sh $BINDIR/fsb-abersoft11k
eval ${INSTALLCMD}fsb-abersoft16k.sh $BINDIR/fsb-abersoft16k
eval ${INSTALLCMD}fsb-abersoft.sh $BINDIR/fsb-abersoft
eval ${INSTALLCMD}fsb-fb.sh $BINDIR/fsb-fb
eval ${INSTALLCMD}fsb-fbs.sh $BINDIR/fsb-fbs
eval ${INSTALLCMD}fsb-mgt.sh $BINDIR/fsb-mgt
eval ${INSTALLCMD}fsb-superforth.sh $BINDIR/fsb-superforth
eval ${INSTALLCMD}fsb-tap.sh $BINDIR/fsb-tap
