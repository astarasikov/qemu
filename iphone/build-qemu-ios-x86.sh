#!/bin/bash

export QEMU_IOS_ROOT="${QEMU_IOS_ROOT:-/Users/alexander/Documents/workspace/builds/apps/qemu-ios-root}"
mkdir -p $QEMU_IOS_ROOT

export ARCH="arm64"
export SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)

export AR=$(xcrun --sdk iphoneos --find ar)
export AS=$(xcrun --sdk iphoneos -f as)
export CC=$(xcrun --sdk iphoneos --find clang)
export CXX=$(xcrun --sdk iphoneos --find clang++)
export LD=$(xcrun --sdk iphoneos -f ld)
export NM=$(xcrun --sdk iphoneos -f nm)
export RANLIB=$(xcrun --sdk iphoneos --find ranlib)

# if you've installed GNU binutils and GCC via Homebrew
# configure will pick up /usr/local/bin/ar and /usr/local/bin/ranlib
# instead of the SDK ones and clang will not link that
export PATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin:$PATH
export PATH=$(dirname $0)/bin:$PATH

export PREFIX_GLIB=${QEMU_IOS_ROOT}/dependencies/glib/arm64
export PREFIX_GLIB_LIB=${QEMU_IOS_ROOT}/dependencies/glib/arm64/lib/glib-2.0
export PREFIX_GETTEXT=${QEMU_IOS_ROOT}/dependencies/gettext/arm64
export PREFIX_LIBICONV=${QEMU_IOS_ROOT}/dependencies/libiconv/arm64
export PREFIX_PIXMAN=${QEMU_IOS_ROOT}/dependencies/pixman/arm64

./configure \
	--target-list=i386-softmmu \
	--host-cc=clang \
	--cc=$CC \
	--cxx=$CXX \
	--extra-cflags="-arch $ARCH -isysroot $SDKROOT -I$PREFIX_GLIB/include/glib-2.0 -I$PREFIX_GLIB_LIB/include -I$PREFIX_GETTEXT/include -I$PREFIX_LIBICONV/include -I$PREFIX_PIXMAN/include/pixman-1" \
	--extra-ldflags="-arch $ARCH -isysroot $SDKROOT -L$PREFIX_GLIB/lib -lglib-2.0 -L$PREFIX_GETTEXT/lib -lintl -L$PREFIX_LIBICONV/lib -liconv -L$PREFIX_PIXMAN/lib -lpixman-1" \
	--audio-drv-list= \
	--enable-tcg-interpreter \
	--enable-debug-tcg \
	--enable-debug-info \
	--disable-werror \
	--disable-slirp \
	--disable-gnutls \
	--disable-nettle \
	--disable-vnc \
	--disable-capstone \
	--disable-tools \
	--disable-libusb \
	--disable-xen \
	--disable-glusterfs \
	--disable-opengl \
	--disable-gtk \
	--disable-hax \
	--disable-virtfs \
	--disable-libnfs \
	--disable-smartcard \
	--disable-libiscsi \
	--disable-libssh2 \
	--disable-seccomp \
	--disable-usb-redir \
	--disable-libpmem \
	--disable-fdt \
	--disable-coroutine-pool
