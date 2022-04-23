#!/bin/sh
SUDO=doas
command -V $SUDO 2> /dev/null > /dev/null || SUDO=sudo
[ $(id -u) -eq 0 ] || $SUDO "$0" "$@"

mkdir build/chroot/tmp
mkdir build/chroot/sys
mkdir build/chroot/proc
mkdir build/chroot/dev

mount -t tmpfs tmpfs build/chroot/tmp
mount -t sysfs sysfs build/chroot/sys
mount -t proc proc build/chroot/proc
mount --bind /dev build/chroot/dev

PATH=/sbin:/bin:/usr/sbin:/usr/bin chroot build/chroot /bin/sh

umount build/chroot/tmp
umount build/chroot/sys
umount build/chroot/proc
umount build/chroot/dev

rmdir build/chroot/tmp
rmdir build/chroot/sys
rmdir build/chroot/proc
rmdir build/chroot/dev
