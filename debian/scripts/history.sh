#!/bin/bash

if [ -z "$1" ] || [ ! -f "debian/changelog" ]
then
	exit 1
fi

wget -O - -q 'http://piwik.org/changelog/' | \
	sed -n "/List of.*tickets closed in Piwik $1[<:]/,/<\/div>/p" | \
	grep 'dev.piwik.org/trac/ticket' | \
	sed -e :a -e 's/<[^>]*>//g;/</N;//ba' | \
	recode HTML..UTF-8 | recode UTF-8..ascii | \
	sed 's/\^A//g' | \
	sed -r 's/^(#[0-9]+)([ ]+)(.*)/\3 (Closes: \1)/g' | while read LINE
do
	debchange --changelog debian/changelog -a -- ${LINE}
done
