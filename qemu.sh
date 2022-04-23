#!/bin/sh
fatal() {
echo "$@"
exit 1
}
[ -d build/chroot ] || fatal "run ./chroot.sh first"

qemu-system-x86_64 -drive if=pflash,format=raw,file="/usr/share/qemu/edk2-x86_64-code.fd" \
-nographic -net none -m 1024 \
-hda build/iglunix.img
