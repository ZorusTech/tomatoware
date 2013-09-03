#!/bin/bash

set -e
set -x

BASE=`pwd`
SRC=$BASE/src
PATCHES=$BASE/patches
RPATH=/opt/lib
DEST=$BASE/opt
LDFLAGS="-L$DEST/lib -s -Wl,--dynamic-linker=/opt/lib/ld-uClibc.so.0 -Wl,-rpath,$RPATH -Wl,-rpath-link,$DEST/lib"
CPPFLAGS="-I$DEST/include -I$DEST/include/ncurses"
CFLAGS="-mtune=mips32 -mips32"
CONFIGURE="./configure --prefix=/opt --host=mipsel-linux"
MAKE="make -j`nproc`"

########## ##################################################################
# NETTLE # ##################################################################
########## ##################################################################

cd $SRC/nettle

if [ ! -f .extracted ]; then
	rm -rf nettle-2.7.1
	tar zxvf nettle-2.7.1.tar.gz
	touch .extracted
fi

cd nettle-2.7.1

if [ ! -f .configured ]; then
	LDFLAGS=$LDFLAGS \
	CPPFLAGS=$CPPFLAGS \
	CFLAGS=$CFLAGS \
	$CONFIGURE
	touch .configured
fi

if [ ! -f .built ]; then
	$MAKE
	touch .built
fi

if [ ! -f .installed ]; then
	make install DESTDIR=$BASE
	touch .installed
fi

########## ##################################################################
# GNUTLS # ##################################################################
########## ##################################################################

export PKG_CONFIG_LIBDIR=$DEST/lib/pkgconfig

cd $SRC/gnutls

if [ ! -f .extracted ]; then
	rm -rf gnutls-3.2.4
	tar xvJf gnutls-3.2.4.tar.xz
	touch .extracted
fi

cd gnutls-3.2.4

if [ ! -f .configured ]; then
	LDFLAGS=$LDFLAGS \
	CPPFLAGS=$CPPFLAGS \
	CFLAGS=$CFLAGS \
	$CONFIGURE \
	--without-p11-kit
	touch .configured
fi

if [ ! -f .built ]; then
	$MAKE
	touch .built
fi

if [ ! -f .installed ]; then
	make install DESTDIR=$BASE
	touch .installed
fi

unset PKG_CONFIG_LIBDIR

########### #################################################################
# IKSEMEL # #################################################################
########### #################################################################

if [ ! -f .edit_sed ]; then
	
	sed -i 's,\/opt\/lib\/libiconv.la,'"$DEST"'\/lib\/libiconv.la,g' \
	$DEST/lib/libgnutls.la

	sed -i 's,\/opt\/lib\/libintl.la,'"$DEST"'\/lib\/libintl.la,g' \
	$DEST/lib/libgnutls.la

	sed -i 's,\/opt\/lib\/libgmp.la,'"$DEST"'\/lib\/libgmp.la,g' \
	$DEST/lib/libgnutls.la
	
	touch .edit_sed
fi	

cd $SRC/iksemel

if [ ! -f .extracted ]; then
	rm -rf iksemel-1.4
	tar zxvf iksemel-1.4.tar.gz
	touch .extracted
fi

cd iksemel-1.4

if [ ! -f .configured ]; then
	LDFLAGS=$LDFLAGS \
	CPPFLAGS=$CPPFLAGS \
	CFLAGS=$CFLAGS \
	$CONFIGURE \
	--with-libgnutls-prefix=$DEST
	touch .configured
fi

if [ ! -f .built ]; then
	$MAKE
	touch .built
fi

if [ ! -f .installed ]; then
	make install DESTDIR=$BASE
	touch .installed
fi

############ ################################################################
# ASTERISK # ################################################################
############ ################################################################

cd $SRC/asterisk

if [ ! -f .extracted ]; then
	rm -rf asterisk-11.5.1
	tar zxvf asterisk-11.5.1.tar.gz
	touch .extracted
fi

cd asterisk-11.5.1

if [ ! -f .configured ]; then
	LDFLAGS=$LDFLAGS \
	CPPFLAGS=$CPPFLAGS \
	CFLAGS=$CFLAGS \
	$CONFIGURE \
	--with-ncurses=$DEST \
	--with-crypto=$DEST \
	--with-iconv=$DEST \
	--with-iksemel=$DEST \
	--with-libcurl=$DEST \
	--with-sqlite3=$DEST \
	--with-ssl=$DEST \
	--with-uuid=$DEST \
	--with-z=$DEST
	touch .configured
fi

if [ ! -f .built ]; then
	ASTCFLAGS=$CPPFLAGS \
	$MAKE
	touch .built
fi

if [ ! -f .installed ]; then
	make install DESTDIR=$BASE
	touch .installed
fi

cd ..

if [ ! -f .installed_example ]; then
	cp .autorun $DEST
	tar zxvf asterisk_gv.tgz -C $DEST/etc        
	tar zxvf config.tgz -C $DEST/etc	
	touch .installed_example
fi