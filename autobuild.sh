#!/bin/sh -e

mkdir -p build

cd build
# TODO: add option for using native toolchain for stage 0
[ -d 'iglunix-bootstrap' ] || git clone --depth=1 https://github.com/iglunix/iglunix-bootstrap
[ -d 'iglunix' ] || git clone --depth=1 https://github.com/iglunix/iglunix
[ -d 'iglupkg' ] || git clone --depth=1 https://github.com/iglunix/iglupkg

cd iglunix-bootstrap
git pull
cd ..
cd iglunix
git pull
cd ..
cd iglupkg
git pull
cd ..

SYSROOT_S2=$(pwd)/sysroot
IP=$(pwd)/iglupkg/

LOGS=$(pwd)/logs

mkdir -p $LOGS

echo === STAGE 1 === Build cross toolchain

cd iglunix-bootstrap

if command -V bad 2> /dev/null; then
	MAKE=gmake bad --gmake ./boot.sh
else
	MAKE=make ./boot.sh
fi

SYSROOT_S1=$(pwd)/sysroot

export CC=$(pwd)/x86_64-iglunix-linux-musl-cc.sh
export CXX=$(pwd)/x86_64-iglunix-linux-musl-c++.sh

cd ..

echo === STAGE 1 === Done

s2_build() {
	PKGDIR=$1
	PKGNAME=$2
	cd $1/$2
	[ -f .s2 ] || ${IP}iglupkg.sh --with-cross=x86_64 --with-cross-dir=$SYSROOT_S1 --for-cross --for-cross-dir=/ fbp
	touch .s2
	# 2>$LOGS/$2.1.err > $LOGS/$2.1.out
	cd ../../
}

s2_extract() {
	PKGDIR=$1
	PKGNAME=$2
	cd $1/$2/out
	tar -xf $2-*.tar.zst -C $SYSROOT_S2 -I zstd
	cd ../../../
}


cd iglunix

echo === STAGE 2 === Build cross libs

s2_build linux musl
s2_build linux linux
s2_build base libunwind
s2_build base libcxx

echo === STAGE 2 === Assemble sysroot

[ -d "$SYSROOT_S2" ] || {
	mkdir -p $SYSROOT_S2
	
	s2_extract linux musl
	s2_extract linux linux
	s2_extract base libunwind
	s2_extract base libcxx
}

echo === STAGE 3 === Build target packages

s3_build() {
	PKGDIR=$1
	PKGNAME=$2
	cd $1/$2
	[ -f .s3 ]  || ${IP}iglupkg.sh --with-cross=x86_64 --with-cross-dir=$SYSROOT_S2 fbp
	touch .s3
	# 2>$LOGS/$2.2.err > $LOGS/$2.2.out
	cd ../../
}

s3_build linux linux
s3_build linux musl
s3_build linux busybox
s3_build base mksh
s3_build base toybox
s3_build base libunwind
s3_build base libcxx
s3_build base llvm

touch .autobuilt

# order to build packages
#
# build stage 1 cross toolchain with stage 0:
#
# linux
# musl
# libunwind
# libcxx
# ...
#
# build stage 2 final packages
#
# linux
# musl
# libunwind
# libcxx
# llvm
# 
# mksh
# toybox
# busybox
# clang
