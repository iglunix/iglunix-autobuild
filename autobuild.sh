#!/bin/sh -e


help_function() {
	printf %b \
		"Usage: $0 [-ch]\n"	\
		'\t-c\tenable color output\n'	\
		'\t-h\tprint this help screen\n'
	exit 0
}

print_info() {
	if [ "$arg_c" -eq 1 ]; then
		printf "%b" "\033[1;36m$1\n\033[m"
	else
		printf "%b" "$1\n"
	fi
}

print_err() {
	if [ "$arg_c" -eq 1 ]; then
		printf "%b" "\033[0;31m$1\n\033[m"
	else
		printf "%b" "$1\n"
	fi
}

on_exit() {
  print_err "ERROR: the last step killed me :("
  if [ $SILENT -eq 1 ]; then
  	print_err "HELP:  use tail on the last step in the log directory."
  fi
}
trap on_exit EXIT

SILENT=0
DEBUG=0

while getopts "chsd" opt
do
	case "$opt" in
		c ) arg_c=1 ;;
		h ) help_function ;;
		s ) SILENT=1;;
		d ) DEBUG=1;;
		? ) help_function ;;
	esac
done

mkdir -p build
cd build
if [ "$DEBUG" -eq 0 ]; then
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
fi

SYSROOT_S2=$(pwd)/sysroot
IP=$(pwd)/iglupkg/

LOGS=$(pwd)/logs

mkdir -p $LOGS

print_info "=== STAGE 1 === Build cross toolchain"

cd iglunix-bootstrap

if command -V bad 2> /dev/null; then
	MAKE=gmake bad --gmake ./boot.sh 2>$LOGS/boot.1.err > $LOGS/boot.1.out
else
	MAKE=make ./boot.sh 2>$LOGS/boot.1.err > $LOGS/boot.1.out
fi

SYSROOT_S1=$(pwd)/sysroot

export CC=$(pwd)/x86_64-iglunix-linux-musl-cc.sh
export CXX_INCL=$(pwd)/x86_64-iglunix-linux-musl-c++.sh
export CXX_NOINCL=$(pwd)/x86_64-iglunix-linux-musl-c++-no-incl.sh
export CXX=$CXX_INCL

cd ..

print_info "=== STAGE 1 === Done"

s2_build() {
	PKGDIR=$1
	PKGNAME=$2
	cd $1/$2
	print_info "== Building $1/$2 =="
	if [ $SILENT -eq 0 ]; then
		[ -f .s2 ] || ${IP}iglupkg.sh --with-cross=x86_64 --with-cross-dir=$SYSROOT_S1 --for-cross --for-cross-dir= fbp
	else
		[ -f .s2 ] || ${IP}iglupkg.sh --with-cross=x86_64 --with-cross-dir=$SYSROOT_S1 --for-cross --for-cross-dir= fbp 2>$LOGS/$2.1.err > $LOGS/$2.1.out
	fi
	touch .s2
	cd ../../
}

s2e_build() {
	PKGDIR=$1
	PKGNAME=$2
	cd $1/$2
	print_info "== Building $1/$2 =="
	if [ $SILENT -eq 0 ]; then
		[ -f .s2 ] || ${IP}iglupkg.sh --with-cross=x86_64 --with-cross-dir=$SYSROOT_S2 --for-cross --for-cross-dir= fbp
	else
		[ -f .s2 ] || ${IP}iglupkg.sh --with-cross=x86_64 --with-cross-dir=$SYSROOT_S2 --for-cross --for-cross-dir= fbp 2>$LOGS/$2.1.err > $LOGS/$2.1.out
	fi
	
	touch .s2
	cd ../../
}

s2_extract() {
	PKGDIR=$1
	PKGNAME=$2
	cd $1/$2/out
	print_info "== Extracting $1/$2 =="
	tar -xf $2-*.tar.zst -C $SYSROOT_S2 -I zstd
	cd ../../../
}


cd iglunix

print_info "=== STAGE 2 === Build cross libs"

s2_build linux musl
s2_build linux linux
s2_build base libunwind
export CXX=$CXX_NOINCL
s2_build base libcxx
export CXX=$CXX_INCL

print_info "=== STAGE 2 === Assemble sysroot"

mkdir -p $SYSROOT_S2
s2_extract linux musl
s2_extract linux linux
s2_extract base libunwind
s2_extract base libcxx

print_info "=== STAGE 2 === Build extra libs"

s2e_build base zlib-ng
sync
s2_extract base zlib-ng
s2e_build base libelf
sync
s2_extract base libelf
s2e_build base openssl
sync
s2_extract base openssl

print_info "=== STAGE 3 === Build target packages"

s3_build() {
	PKGDIR=$1
	PKGNAME=$2
	cd $1/$2
	print_info "== Building $1/$2 =="
	if [ $SILENT -eq 0 ]; then
		[ -f .s3 ]  || ${IP}iglupkg.sh --with-cross=x86_64 --with-cross-dir=$SYSROOT_S2 fbp
	else
		[ -f .s3 ]  || ${IP}iglupkg.sh --with-cross=x86_64 --with-cross-dir=$SYSROOT_S2 fbp 2>$LOGS/$2.1.err > $LOGS/$2.1.out
	fi
	
	touch .s3
	# 2>$LOGS/$2.2.err > $LOGS/$2.2.out
	cd ../../
}

s3_build linux limine
s3_build linux linux
s3_build linux make_ext4fs
s3_build linux musl
s3_build linux busybox
s3_build base mksh
s3_build base toybox
s3_build base compiler-rt
s3_build base libunwind
export CXX=$CXX_NOINCL
s3_build base libcxx
export CXX=$CXX_INCL
s3_build base llvm
s3_build base oslo
s3_build base zlib-ng
s3_build base bmake
s3_build base byacc
s3_build base curl
s3_build base openssl
s3_build base doas
s3_build base expat
s3_build base flex
s3_build base libelf
s3_build base man-pages-posix
s3_build base netbsd-curses
s3_build base om4
s3_build base samurai
s3_build base zstd

s3_build bad bad
s3_build bad gmake

touch .autobuilt

trap - EXIT

# TODO
# - add wrapper scripts to use stage 2 sysroot in stage 3 instead of stage 1.
# - get whole of base cross compiling

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
