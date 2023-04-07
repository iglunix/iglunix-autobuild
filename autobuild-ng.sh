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

mkdir -p ./sysroot/usr/bin
cp $(command -V qemu-$1-static | rev | cut -d' ' -f1 | rev) ./sysroot/usr/bin/

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
atb base/installer
atb linux/musl
atb linux/busybox
atb base/toybox
atb base/flex
atb base/samurai
atb base/pkgconf
atb base/perl
atb base/openssl
atb base/oslo
atb linux/linux
atb base/dhcpcd
atb base/init
atb base/cmake
atb base/curl
atb base/libffi
atb base/zlib-ng
atb base/python
atb base/compiler-rt
atb base/libcxx
atb base/llvm
atb linux/make_ext4fs
atb base/netbsd-curses
atb base/man-pages-posix

# We MUST build zstd last otherwise all our
# output packages will be zstd compressed
atb base/zstd

to_build=$(cat $tbf)
rm -f $tbf

cd build
BUILD_BASE=$(pwd)

IGLUPKG_BASE=$(pwd)/iglupkg
if [ ! -d "$IGLUPKG_BASE" ]
then
	git clone https://github.com/iglunix/iglupkg
fi
git pull

IGLUPKG=$IGLUPKG_BASE/iglupkg.sh

IGLUNIX_BASE=$(pwd)/iglunix
if [ ! -d "$IGLUNIX_BASE" ]
then
	git clone https://github.com/iglunix/iglunix
fi
cd iglunix
git pull

for pkg in $to_build; do
	cd $pkg
	$IGLUPKG f
	sudo chroot $CHROOT /usr/bin/env PATH=/usr/sbin:/usr/bin:/sbin:/bin /build_pkg.sh $pkg
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
efi base/dhcpcd
efi base/init
efi base/installer
efi base/zlib-ng
efi linux/make_ext4fs
efi base/zstd

# The actual kernel is not needed inside the initrd.
mv $BUILD_BASE/initrd/boot/vmlinuz $BUILD_BASE/vmlinuz

cd initrd

cat > init << EOF
#!/bin/sh
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

exec /sbin/init

EOF

cat > etc/hostname << EOF
iglunix
EOF

cat > etc/passwd << EOF
root:x:0:0:Admin,,,:/root:/bin/sh
EOF

cat > etc/group << EOF
root:x:0:
EOF

chmod +x init

find . | cpio -H newc -o > $BUILD_BASE/initrd.cpio
cd $BUILD_BASE

dd if=/dev/zero of=disk.img bs=1M count=256
mkfs.vfat -n 'IGLUNIX_IMG' disk.img
mkdir -p boot-disk
sudo mount disk.img boot-disk
sudo cp $BUILD_BASE/initrd.cpio boot-disk/initrd
sudo cp $BUILD_BASE/vmlinuz boot-disk

sudo tar -xf $IGLUNIX_BASE/base/oslo/out/*.*.tar -C boot-disk
sudo mv boot-disk/boot/efi boot-disk/
sudo rmdir boot-disk/boot
sudo cp $IGLUNIX_BASE/pkgs.tar.zst boot-disk/
sudo find boot-disk
sudo umount boot-disk
sync
