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

mkdir -p ./sysroot/etc
printf 'root:x:0:root\n' > ./sysroot/etc/group
printf 'root:x:0:0:,,,:/root:/bin/sh' > ./sysroot/etc/passwd

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

CHROOT=$(pwd)/sysroot
BASE=$(pwd)

cp build_pkg.sh $CHROOT
chmod +x $CHROOT/build_pkg.sh

to_build="base/mksh
base/bmake
base/byacc
base/om4
bad/bad
bad/gmake
base/flex
base/samurai
base/pkgconf
base/openssl
base/cmake"

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
	sudo chroot $CHROOT /build_pkg.sh $pkg
	cd $IGLUNIX_BASE
done
