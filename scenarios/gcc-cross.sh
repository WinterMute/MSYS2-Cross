#!/bin/bash

#
# The BSD 3-Clause License. http://www.opensource.org/licenses/BSD-3-Clause
#
# This file is part of 'MSYS2-Cross' project.
# Copyright (c) 2013 by Alexpux (alexpux@gmail.com)
# All rights reserved.
#
# Project: MSYS2-Cross ( https://github.com/Alexpux/MSYS2-Cross )
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the distribution.
# - Neither the name of the 'MSYS2-Cross' nor the names of its contributors may
#     be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# **************************************************************************

P=gcc-cross
P_V=gcc-${GCC_VERSION}
SRC_FILE="$P_V.tar.bz2"
URL=ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-${GCC_VERSION}/${SRC_FILE}
DEPENDS=()

src_download() {
	func_download $P_V ".tar.bz2" $URL
}

src_unpack() {
	func_uncompress $P_V ".tar.bz2"
}

src_patch() {
	local _patches=(
		gcc/gcc-${GCC_VERSION}-msys.patch
	)

	func_apply_patches \
		$P_V \
		_patches[@]
}

src_configure() {

	[[ ! -f $SRC_DIR/$P_V/msys.marker ]] && {
		echo -n "---> Copy msys sources to GCC source tree..."
		cp -rf $SRC_DIR/msys2/newlib $SRC_DIR/$P_V/ || die "Fail to copy newlib sources"
		cp -rf $SRC_DIR/msys2/winsup $SRC_DIR/$P_V/ || die "Fail to copy winsup sources"
		echo "done"
		touch $SRC_DIR/$P_V/msys.marker
	}

	[[ ! -f $SRC_DIR/$P_V/w32api-old.marker ]] && {
		echo -n "---> Remove old win32api from source tree..."
		[[ -d $SRC_DIR/$P_V/winsup/w32api ]] && {
			rm -rf $SRC_DIR/$P_V/winsup/w32api/* || die "Fail to remove old win32api"
		}
		echo "done"
		touch $SRC_DIR/$P_V/w32api-old.marker
	}

	[[ ! -f $SRC_DIR/$P_V/w32api-new.marker ]] && {
		echo -n "---> Copy new win32api to source tree..."
		mkdir -p $SRC_DIR/$P_V/winsup/w32api/{include,lib}
		cp -rf $PREFIX/include/w32api/* $SRC_DIR/$P_V/winsup/w32api/include/ || die "Fail to copy new win32api headers"
		cp -rf $PREFIX/lib/w32api/* $SRC_DIR/$P_V/winsup/w32api/lib/ || die "Fail to copy new win32api libraries"
		echo "done"
		touch $SRC_DIR/$P_V/w32api-new.marker
	}

	local _conf_flags=(
		--prefix=/usr
		--sysconfdir=/etc
		--build=$HOST
		--target=$TARGET
		--disable-nls
		--enable-languages=c,c++
		--disable-shared
		--disable-threads
		--disable-multilib
		--disable-werror
		--enable-version-specific-runtime-libs
		--with-newlib
		--with-windows-headers=$PREFIX/include/w32api
		--with-windows-libs=$PREFIX/lib/w32api
		--disable-rpath
		--disable-sjlj-exceptions
		--with-dwarf2
		--disable-win32-registry
		--with-gnu-ld
		--with-gnu-as
		--with-gmp=${PREFIX}/prereq
		--with-mpfr=${PREFIX}/prereq
		--with-mpc=${PREFIX}/prereq
		CFLAGS="\"${HOST_CFLAGS}\""
		LDFLAGS="\"${HOST_LDFLAGS}\""
		CPPFLAGS="\"${HOST_CPPFLAGS}\""
	)

	local _allconf=${_conf_flags[@]}
	func_configure $P $P_V "$_allconf"
}

pkg_build() {
	local _make_flags=(
		${MAKE_OPTS}
		all-gcc
	)
	local _allmake="${_make_flags[@]}"
	func_make \
		${P} \
		"/bin/make" \
		"$_allmake" \
		"building gcc..." \
		"built-gcc"
	
	_make_flags=(
		${MAKE_OPTS}
		DESTDIR=$PREFIX
		install-gcc
	)
	_allmake="${_make_flags[@]}"
	func_make \
		${P} \
		"/bin/make" \
		"$_allmake" \
		"installing gcc..." \
		"install-gcc"

	_make_flags=(
		${MAKE_OPTS}
	)
	_allmake="${_make_flags[@]}"
	func_make \
		${P} \
		"/bin/make" \
		"$_allmake" \
		"building all..." \
		"built-all"
}

pkg_install() {
	local _install_flags=(
		${MAKE_OPTS}
		DESTDIR=$PREFIX
		install
	)
	local _allinstall="${_install_flags[@]}"
	func_make \
		${P} \
		"/bin/make" \
		"$_allinstall" \
		"installing all..." \
		"installed-all"
}
