#!/bin/bash

if [ "$1" = "commitrelease" ]
then
	if [ ! -r "debian/changelog" ]
	then
		echo "Cannot read debian/changelog"
		exit 1
	fi

	if [ "$(git status --short . | grep -v 'debian/changelog' | wc -l)" -ne 0 ]
	then
		echo "One or more files needs to be committed"
		exit 1
	else
		git commit -S -m "$(head -n 1 debian/changelog)" debian/changelog
	fi
fi
