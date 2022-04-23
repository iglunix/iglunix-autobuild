#!/bin/sh -e
# generate the installer initcpio image
mkdir -p build/initrd/

cex() {
	PKGDIR=$1
	PKGNAME=$2
	tar -xf build/iglunix/$PKGDIR/$PKGNAME/out/$PKGNAME.*.tar.zst -I zstd -C build/initrd
}

cex linux musl
cex linux make_ext4fs
cex linux busybox
cex base mksh
cex base toybox
cex base zlib-ng # for make_ext4fs and zstd
cex base zstd # for extracting tarballs
cex linux limine # for installing mbr bootloader

cat > build/initrd/init <<EOF
#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin

mkdir -p /dev
mkdir -p /tmp
mkdir -p /proc
mkdir -p /sys
mkdir -p /mnt

mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t tmpfs tmpfs /tmp
mdev -s
mdev -d

echo 0 > /proc/sys/kernel/printk

mount \$(findfs LABEL=IGLUNIX) /mnt

exec /sbin/init
EOF

chmod +x build/initrd/init

cd build/initrd/
find . | cpio -o -H newc > ../initrd.cpio
cd ..
gzip -f initrd.cpio > initrd.cpio.gz
cd ..
