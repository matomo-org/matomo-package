#!/bin/bash
# 0 if equal
# 1 first is lowest
# 2 second is lowest

if [[ -z "$1" ]] || [[ -z "$2" ]]; then
	exit 1
fi
if [[ "$1" == "$2" ]]; then
	echo 0
fi

if [[ "$(echo -e "$1\n$2" | sort --version-sort | head -n1)" == "$1" ]]; then
	echo 1
else
	echo 2
fi
