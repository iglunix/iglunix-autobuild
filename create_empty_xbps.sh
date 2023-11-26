#!/bin/sh -e
if [ -z "$ARCH" ]
then
	ARCH=x86_64
fi

mkdir -p empty

xbps-create -A $ARCH-musl -n $1-0.0.1_1 -s "empty filler package" empty
