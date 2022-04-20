#!/bin/sh -e
cd build
# [ -f iglunix/.autobuilt ] || echo "ERROR: you need to run autobuild.sh first"
CHROOT=$(pwd)/chroot
mkdir -p $CHROOT

cex() {
	PKGDIR=$1
	PKGNAME=$2
	tar -xf iglunix/$PKGDIR/$PKGNAME/out/$PKGNAME.*.tar.zst -I zstd -C $CHROOT
}

cex linux musl
cex linux busybox
cex base mksh
cex base toybox
cex base compiler-rt
cex base libunwind
cex base libcxx
cex base llvm
