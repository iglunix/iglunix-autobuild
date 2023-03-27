#!/bin/sh -e

if [ -z "$1" ]; then
	export ARCH=x86_64
else
	export ARCH=$1
fi

if [ ! -z "$GITHUB_TOKEN" ]; then
	./fetch_latest.sh
fi

if [ ! -d "./sysroot" ]; then
	printf '%s\n' 'Must provide ./sysroot or provide $GITHUB_TOKEN to download one!'
fi

