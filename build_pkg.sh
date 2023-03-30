#!/bin/sh -e

[ ! -z "$1" ]

printf 'I should be building package: %s\n' $1

cd /build/iglunix/$1

LOG=$(mktemp)

if ! /build/iglupkg/iglupkg.sh bp > $LOG; then
	cat $LOG
fi

tar -tf out/$(basename "$1").*.tar
tar -xf out/$(basename "$1").*.tar -C /
printf 'Done building package: %s\n' $1
