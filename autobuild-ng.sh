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

tbf=$(mktemp)

atb() {
	printf '%s\n' $1 >> $tbf
}

atb base/mksh
atb base/bmake
atb base/byacc
atb base/om4
atb bad/bad
atb bad/gmake
atb linux/musl
atb linux/busybox
atb base/toybox
atb base/flex
atb base/samurai
atb base/pkgconf
atb base/perl
atb base/openssl
# atb base/cmake
# atb base/curl
# atb base/libffi
# atb base/zlib-ng
# atb base/python
atb base/oslo
# atb base/netbsd-curses
# atb base/man-pages-posix
atb linux/linux

to_build=$(cat $tbf)
rm -f $tbf

cd build
BUILD_BASE=$(pwd)

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

tar -cf pkgs.tar */*/out/*.*.tar
zstd --ultra -22 pkgs.tar

cd $BUILD_BASE

efi() {
	tar -xf $IGLUNIX_BASE/$1/out/*.*.tar -C $BUILD_BASE/initrd
}

echo === Assembling initrd ===
mkdir -p $BUILD_BASE/initrd
efi linux/linux
efi linux/busybox
efi linux/musl
efi base/toybox
efi base/mksh

# The actual kernel is not needed inside the initrd.
mv $BUILD_BASE/initrd/boot/vmlinuz $BUILD_BASE/vmlinuz

cd initrd

cat > init << EOF
#!/bin/sh
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

mkdir -p /dev
mkdir -p /tmp
mkdir -p /sys
mkdir -p /proc

mount -t tmpfs tmpfs /dev
mount -t tmpfs tmpfs /tmp
mount -t sysfs sysfs /sys
mount -t proc proc /proc

exec /bin/sh

EOF

chmod +x init

find . | cpio -H newc -o > $BUILD_BASE/initrd.cpio
cd $BUILD_BASE
