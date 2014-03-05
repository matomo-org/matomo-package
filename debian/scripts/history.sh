#!/bin/bash

if [ -z "$1" ] || [ ! -f "debian/changelog" ]
then
	exit 1
fi

PIWIK_VERSION="$1"
if [ "$(echo $PIWIK_VERSION | sed 's/\([0-9]\)\.\([0-9]\).\([0-9]\).*/\3/')" -eq "0" ]
then
	PIWIK_VERSION="$(echo $PIWIK_VERSION | sed 's/\([0-9]\)\.\([0-9]\).\([0-9]\).*/\1.\2/')"
fi

if [ ! -z "$2" ] && [ "$2" = "--test" ]
then
	echo "Test mode enabled, not adding entries to debian/changelog"
	TEST_MODE=1
else
	TEST_MODE=0
fi

CHANGELOG_URL=$(wget -O - -q 'http://piwik.org/changelog/' | grep "Piwik $1" | sed 's/.*<a href=\([^>]*\).*/\1/' | sed -e 's/"//g' -e "s/'//g")

if [ -z "$(echo $CHANGELOG_URL | grep -i http)" ]
then
	echo "Cannot find changelog url"
	exit 2
fi

echo "Changelog url found at $CHANGELOG_URL"

# determines if we managed to find some history in the changelog page
wget -O - -q "$CHANGELOG_URL" | \
	sed -n "/List of.*in Piwik $PIWIK_VERSION.*>$/,/<\/div>/p;" | \
	grep 'dev.piwik.org/trac/ticket' | \
	sed -e :a -e 's/<[^>]*>//g;/</N;//ba' | \
	recode HTML..UTF-8 | recode UTF-8..ascii | \
	sed 's/\^A//g' | \
	sed -r 's/^(#[0-9]+)([ ]+)(.*)/\3 (Closes: \1)/g' | while read LINE
do
	if [ "$TEST_MODE" -eq "1" ]
	then
		echo "  * ${LINE}"
	else
		debchange --changelog debian/changelog -a -- ${LINE}
	fi
done
