#!/bin/bash

if [ -z "$1" ] || [ ! -f "debian/changelog" ]
then
	exit 1
fi

CHANGELOG_URL=$(wget -O - -q 'http://piwik.org/changelog/' | grep "Piwik $1" | sed 's/.*<a href=\([^>]*\).*/\1/' | sed -e 's/"//g' -e "s/'//g")

if [ -z "$(echo $CHANGELOG_URL | grep -i http)" ]
then
	echo "not a valid url"
	exit 2
fi

wget -O - -q "$CHANGELOG_URL" | \
	sed -n "/List of.*tickets closed in Piwik $1[<:]/,/<\/div>/p; /List of.*tickets fixed in Piwik 2.0[<:]/,/<\/div>/p;" | \
	grep 'dev.piwik.org/trac/ticket' | \
	sed -e :a -e 's/<[^>]*>//g;/</N;//ba' | \
	recode HTML..UTF-8 | recode UTF-8..ascii | \
	sed 's/\^A//g' | \
	sed -r 's/^(#[0-9]+)([ ]+)(.*)/\3 (Closes: \1)/g' | while read LINE
do
	debchange --changelog debian/changelog -a -- ${LINE}
done
