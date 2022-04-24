#!/bin/sh -e
./initrd.sh
dd if=/dev/zero of=build/iglunix.img bs=1M count=1
dd if=/dev/zero of=build/iglunix.img.1 bs=1M count=512
mkfs.vfat -n IGLUNIX build/iglunix.img.1
mount build/iglunix.img.1 /mnt

cp -r build/chroot/boot/* /mnt
# uncomment to use limine for UEFI booting aswell
# cp build/chroot/usr/share/limine/BOOTX64.EFI /mnt/efi/boot/bootx64.efi
cp build/chroot/usr/share/limine/limine.sys /mnt

cat > /mnt/limine.cfg <<EOF
TIMEOUT=5

:Linux

PROTOCOL=linux
KERNEL_PATH=boot:///vmlinuz
CMDLINE=
MODULE_PATH=boot:///initrd
EOF

cp build/initrd.cpio.gz /mnt/initrd
iex() {
	PKGDIR=$1
	PKGNAME=$2
	cp build/iglunix/$PKGDIR/$PKGNAME/out/$PKGNAME.*.tar.zst /mnt
}



iex linux limine
iex linux linux
iex linux make_ext4fs
iex linux musl
iex linux busybox
iex base mksh
iex base toybox
iex base compiler-rt
iex base libunwind
iex base libcxx
iex base llvm
iex base oslo
iex base zlib-ng
iex base bmake
iex base byacc
iex base curl
iex base openssl
iex base doas
iex base expat
iex base flex
iex base libelf
iex base man-pages-posix
iex base netbsd-curses
iex base om4
iex base samurai
iex base zstd

iex bad bad
iex bad gmake

umount /mnt
sync
dd if=build/iglunix.img.1 of=build/iglunix.img bs=1M seek=1
fdisk build/iglunix.img < img.fdisk

./build/chroot/lib/ld-musl-x86_64.so.1 ./build/chroot/usr/bin/limine-deploy ./build/iglunix.img

zstd build/iglunix.img --ultra -22
