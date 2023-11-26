#!/bin/sh -e

[ ! -z "$1" ]

printf 'I should be building package: %s\n' $1

cd /build/iglunix/$1

LOG=$(mktemp)

if false
then
	if ! /build/iglupkg/iglupkg.sh bp > $LOG; then
		cat $LOG
	fi
else
	/build/iglupkg/iglupkg.sh bp
fi

printf 'Done building package: %s\n' $1
