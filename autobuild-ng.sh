#!/bin/sh -e

if [ -z "$1" ]; then
	export ARCH=x86_64
else
	export ARCH=$1
fi

if [ ! -z "$GITHUB_TOKEN" ]; then
	while ! ./fetch_latest.sh; do
    		sleep 5
	done
fi

if [ ! -d "./sysroot" ]; then
	printf '%s\n' 'Must provide ./sysroot or provide $GITHUB_TOKEN to download one!'
fi

mkdir -p build

# setup chroot
mkdir -p ./sysroot/tmp
mkdir -p ./sysroot/dev
mkdir -p ./sysroot/sys
mkdir -p ./sysroot/proc
mkdir -p ./sysroot/build

sudo mount --bind /tmp ./sysroot/tmp
sudo mount --bind /dev ./sysroot/dev
sudo mount --bind /sys ./sysroot/sys
sudo mount --bind /proc ./sysroot/proc
sudo mount --bind $(pwd)/build ./sysroot/build

sudo chroot ./sysroot /usr/bin/clang --version

CHROOT=$(pwd)/chroot
BASE=$(pwd)

to_build="linux/musl
base/mksh
base/toybox
"

cd build
git clone https://github.com/iglunix/iglupkg
IGLUPKG_BASE=$(pwd)/iglupkg
IGLUPKG=$IGLUPKG_BASE/iglupkg.sh

git clone https://github.com/iglunix/iglunix
cd iglunix
IGLUNIX_BASE=$(pwd)

for pkg in $to_build; do
	cd $pkg
	$IGLUPKG f
	cd $IGLUNIX_BASE
done
