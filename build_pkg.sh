#!/bin/sh -e

[ ! -z "$1" ]

printf 'I should be building package: %s\n' $1

cd /build/iglunix/$1

/build/iglupkg/iglupkg.sh bp

tar -xf out/$(basename "$1").*.tar -C /
printf 'Done building package: %s\n' $1
