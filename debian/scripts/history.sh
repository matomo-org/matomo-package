#!/bin/bash

# warning: this script tries to deal with UTF-8 aliens (not gremlins)
# this means some UTF-8 entities are replaced on the fly so recode doesn't
# complain during the intermediate conversion steps.
# note: I'm quite unsure as to why some characters aren't converted nicely
# compared to others as FF seems to display them correctly. Feedback and help
# welcome.

# this is a regexp for sed.
# http://www.ascii.cl/htmlcodes.htm
UTF8_ALIENS='s/#8243/#8221/g; s/#8211/#45/g; s/#8216/#39/g; s/#8242/#39/g;'

if [ -z "$1" ] || [ ! -f "debian/changelog" ]
then
	exit 1
fi

if [ ! -z "$2" ] && [ "$2" = "--test" ]
then
	echo "Test mode enabled, not adding entries to debian/changelog"
	TEST_MODE=1
else
	TEST_MODE=0
fi

if [ ! -x /usr/bin/recode ]
then
	echo "You need to install 'recode' (apt-get install recode -V -y)"
	exit 1
fi

#EG Remove last control on version to be more permisive 
#CHANGELOG_URL=$(wget -O - -q 'https://matomo.org/changelog/' | grep "Matomo $1" | sed 's/.*href=\([^>]*\).*/\1/' | sed -e 's/"//g' -e "s/'//g" | grep ^http | grep "$1/")
CHANGELOG_URL=$(wget -O - -q 'https://matomo.org/changelog/' | grep "Matomo.* $1" | sed 's/.*href=\([^>]*\).*/\1/' | sed -e 's/"//g' -e "s/'//g" | grep ^http)

if ! echo "$CHANGELOG_URL" | grep --quiet --ignore-case http
then
	echo "Cannot find changelog url"
	exit 2
fi

echo "Changelog url found at $CHANGELOG_URL"

alt="${1%.*}.x"

wget -O - -q "$CHANGELOG_URL" | \
	sed -n "/List of.*in Matomo \($1\|$alt\).*>$/,/<\/ul>/p;" | \
	grep -e 'dev.matomo.org/trac/ticket' -e 'github.com/matomo-org' | \
	sed -e :a -e 's/<[^>]*>//g;/</N;//ba' | \
	sed '/^$/d' | \
	recode --silent --force UTF-8..ascii | recode UTF-8..HTML | sed -e "${UTF8_ALIENS}" | \
	recode HTML..UTF-8 | recode HTML..UTF-8 | recode UTF-8..ascii | \
	sed 's/\^A//g' | \
	sed -r 's/^(#[0-9]+)([ ]+)(.*)/\3 (Closes: \1)/g' | while read -r LINE
do
	echo "  * ${LINE}"
	if [ "$TEST_MODE" -eq "0" ]
	then
		debchange --changelog debian/changelog -a -- "${LINE}"
	fi
done
