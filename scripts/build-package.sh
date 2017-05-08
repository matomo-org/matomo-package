#!/bin/bash
# Syntax: build-package.sh version

# Before running this script, tag a new version:
# $ git tag 1.11-b3
# $ git push origin tags/1.11-b3

VERSION="$1"

###########################################
# Current Latest Piwik Major Version
# -----------------------------------------
# Update this to the MAJOR VERSION when:
# 1) before releasing a "public stable" of the current major version to ship to everyone,
#    (when piwik.org/download/ and builds.piwik.org/piwik.zip will be updated)
# 2) or before releasing a "public beta" of the new major version to ship to everyone in beta channel
#    (when builds.piwik.org/LATEST_BETA will be updated)
#
#
###########################################
CURRENT_LATEST_MAJOR_VERSION="3"

MAJOR_VERSION=`echo $VERSION | cut -d'.' -f1`

URL_REPO=https://github.com/piwik/piwik.git

LOCAL_REPO="piwik_last_version_git"
LOCAL_ARCH="archives"

REMOTE_SERVER="piwik.org"
REMOTE_LOGIN="piwik-builds"
REMOTE_HTTP_PATH="/home/piwik-builds/www/builds.piwik.org"

# List of Sub-modules that SHOULD be in the packaged release, eg PiwikTracker|CorePluginName
SUBMODULES_PACKAGED_WITH_CORE='log-analytics|plugins/Morpheus/icons'

REMOTE="${REMOTE_LOGIN}@${REMOTE_SERVER}"
REMOTE_CMD="ssh -C ${REMOTE}"

REMOTE_CMD_API="ssh -C piwik-api@${REMOTE_SERVER}"
REMOTE_CMD_WWW="ssh -C piwik@${REMOTE_SERVER}"

API_PATH="/home/piwik-api/www/api.piwik.org/"
WWW_PATH="/home/piwik/www/"

# Setting umask so it works for most users, see https://github.com/piwik/piwik/issues/3869
UMASK=$(umask)
umask 0022

# this is where our build script is.
WORKDIR=$(echo $0 | sed 's,[^/]*$,,; s,/$,,;')
[ -z "$WORKDIR" ] && WORKDIR=$PWD

# this is where our piwik is going to be built
BUILD_DIR=$WORKDIR/../archives/

trap "script_cleanup" EXIT


# check local environment for all required apps/tools
function checkEnv() {
	if [ ! -x "/usr/bin/curl" -o ! -x "$(which curl)" ]
	then
		die "Cannot find curl"
	fi

	if [ ! -x "/usr/bin/git" -o ! -x "$(which git)" ]
	then
		die "Cannot find git"
	fi

	if [ ! -x "/usr/bin/php" -o ! -x "$(which php)" ]
	then
		die "Cannot find php"
	fi

	if [ ! -x "/usr/bin/gpg" -o ! -x "$(which gpg)" ]
	then
		die "Cannot find gpg"
	fi

	if [ ! -x "/usr/bin/zip" -o ! -x "$(which zip)" ]
	then
		die "Cannot find zip"
	fi

	if [ ! -x "/usr/bin/mail" -o ! -x "$(which mail)" ]
	then
		die "Cannot find mail"
	fi

}

# this function is called whenever the script exits
# and it performs some cleanup tasks
function script_cleanup() {

	# FIXME: to be removed once the script has been validated
	# all cleanup actions
	# [ -d "$BUILD_DIR" ] && rm -rf $BUILD_DIR

	# setting back umask
	umask $UMASK
}

# report error and exit
function die() {
	echo -e "$0: $1"
	exit 2
}

# organize files for packaging
function organizePackage() {
	if [ ! -f "composer.phar" ]
	then
		curl -sS https://getcomposer.org/installer | php  || die "Error installing composer "
	fi
	# --ignore-platform-reqs in case the building machine does not have one of the packages required ie. GD required by cpchart
	php composer.phar install --no-dev -o --ignore-platform-reqs || die "Error installing composer packages"

	# delete most submodules
	for P in $(git submodule status | egrep -v $SUBMODULES_PACKAGED_WITH_CORE | awk '{print $2}')
	do
		rm -Rf ./$P
	done

	# ------------
	# WARNING:
	# if you add files below, also update the Integration test in ReleaseCheckListTest.php
	# in isFileDeletedFromPackage()
	# ------------

	echo -e "Deleting un-needed files..."

	rm -rf composer.phar
	rm -rf vendor/twig/twig/test/
	rm -rf vendor/twig/twig/doc/
	rm -rf vendor/symfony/console/Symfony/Component/Console/Resources/bin
	rm -rf vendor/mnapoli/php-di/website
	rm -rf vendor/mnapoli/php-di/news
	rm -rf vendor/mnapoli/php-di/doc
	rm -rf vendor/tecnickcom/tcpdf/examples
	rm -rf vendor/tecnickcom/tcpdf/CHANGELOG.txt
	rm -rf vendor/guzzle/guzzle/docs/

	# Delete un-used files from the piwik-icons repository
	rm -rf plugins/Morpheus/icons/src*
	rm -rf plugins/Morpheus/icons/tools*
	rm -rf plugins/Morpheus/icons/flag-icon-css*
	rm -rf plugins/Morpheus/icons/.git*
	rm -rf plugins/Morpheus/icons/*.py
	rm -rf plugins/Morpheus/icons/*.sh
	rm -rf plugins/Morpheus/icons/*.json
	rm -rf plugins/Morpheus/icons/*.lock
	rm -rf plugins/Morpheus/icons/*.svg

	# Delete un-used fonts
	rm -rf vendor/tecnickcom/tcpdf/fonts/ae_fonts_2.0
	rm -rf vendor/tecnickcom/tcpdf/fonts/dejavu-fonts-ttf-2.33
	rm -rf vendor/tecnickcom/tcpdf/fonts/dejavu-fonts-ttf-2.34
	rm -rf vendor/tecnickcom/tcpdf/fonts/freefont-20100919
	rm -rf vendor/tecnickcom/tcpdf/fonts/freefont-20120503
	rm -rf vendor/tecnickcom/tcpdf/fonts/freemon*
	rm -rf vendor/tecnickcom/tcpdf/fonts/cid*
	rm -rf vendor/tecnickcom/tcpdf/fonts/courier*
	rm -rf vendor/tecnickcom/tcpdf/fonts/aefurat*
	rm -rf vendor/tecnickcom/tcpdf/fonts/dejavusansb*
	rm -rf vendor/tecnickcom/tcpdf/fonts/dejavusansi*
	rm -rf vendor/tecnickcom/tcpdf/fonts/dejavusansmono*
	rm -rf vendor/tecnickcom/tcpdf/fonts/dejavusanscondensed*
	rm -rf vendor/tecnickcom/tcpdf/fonts/dejavusansextralight*
	rm -rf vendor/tecnickcom/tcpdf/fonts/dejavuserif*
	rm -rf vendor/tecnickcom/tcpdf/fonts/freesansi*
	rm -rf vendor/tecnickcom/tcpdf/fonts/freesansb*
	rm -rf vendor/tecnickcom/tcpdf/fonts/freeserifb*
	rm -rf vendor/tecnickcom/tcpdf/fonts/freeserifi*
	rm -rf vendor/tecnickcom/tcpdf/fonts/pdf*
	rm -rf vendor/tecnickcom/tcpdf/fonts/times*
	rm -rf vendor/tecnickcom/tcpdf/fonts/uni2cid*
	
	rm -rf vendor/szymach/c-pchart/src/Resources/fonts/advent_light*
	rm -rf vendor/szymach/c-pchart/src/Resources/fonts/Bedizen*
	rm -rf vendor/szymach/c-pchart/src/Resources/fonts/calibri*
	rm -rf vendor/szymach/c-pchart/src/Resources/fonts/Forgotte*
	rm -rf vendor/szymach/c-pchart/src/Resources/fonts/MankSans*
	rm -rf vendor/szymach/c-pchart/src/Resources/fonts/pf_arma_five*
	rm -rf vendor/szymach/c-pchart/src/Resources/fonts/Silkscreen*
	rm -rf vendor/szymach/c-pchart/src/Resources/fonts/verdana*

	# ------------
	# WARNING: Did you read the WARNING above?
	# ------------

	rm -rf libs/PhpDocumentor-1.3.2/
	rm -rf libs/FirePHPCore/
	rm -rf libs/open-flash-chart/php-ofc-library/ofc_upload_image.php

	rm -rf tmp/*
	rm -f misc/updateLanguageFiles.sh
	rm -f misc/others/db-schema*
	rm -f misc/others/diagram_general_request*
	rm -f .coveralls.yml .scrutinizer.yml .phpstorm.meta.php
	rm -f HIRING.md

	# delete unwanted folders, recursively
	for x in .git ; do
		find . -name "$x" -exec rm -rf {} \;
	done

	# delete unwanted files, recursively
	for x in .gitignore .gitmodules .gitattributes .bowerrc .bower.json \
		.coveralls.yml .editorconfig .gitkeep .jshintrc .php_cs .travis.sh .travis.yml; do
		find . -name "$x" -exec rm -f {} \;
	done

	cp tests/README.md ../

	# Delete all `tests/` and `Tests/` folders
	find ./ -iname 'tests' -type d -prune -exec rm -rf {} \;
	mkdir tests
	mv ../README.md tests/

	# Remove and deactivate the TestRunner plugin in production build
	sed -i '/Plugins\[\] = TestRunner/d' config/global.ini.php
	rm -rf plugins/TestRunner

	cp misc/How\ to\ install\ Piwik.html ..

	if [ -d "misc/package" ]
	then
		cp misc/package/WebAppGallery/* ..
		rm -rf misc/package/
	else
		if [ -e misc/WebAppGallery ]; then
			cp misc/WebAppGallery/* ..
			rm -rf misc/WebAppGallery
		fi
	fi

	find ./ -type f -printf '%s ' -exec md5sum {} \; \
		| grep -v "user/.htaccess" \
		| egrep -v 'manifest.inc.php|autoload.php|autoload_real.php' \
		| sed '1,$ s/\([0-9]*\) \([a-z0-9]*\) *\.\/\(.*\)/\t\t"\3" => array("\1", "\2"),/;' \
		| sort \
		| sed '1 s/^/<?php\n\/\/ This file is automatically generated during the Piwik build process \
namespace Piwik;\nclass Manifest {\n\tstatic $files=array(\n/; $ s/$/\n\t);\n}/' \
		> ./config/manifest.inc.php

}

# check for local requirements
checkEnv

[ ! -z "$VERSION" ] || die "Expected a version number as a parameter"

echo -e "Going to build Piwik $VERSION (Major version: $MAJOR_VERSION)"

if [ "$MAJOR_VERSION" == "$CURRENT_LATEST_MAJOR_VERSION" ]
then
	echo -e "-> Building a new release for the current latest major version (stable or beta)"
	BUILDING_LATEST_MAJOR_VERSION_STABLE_OR_BETA=1
else
	echo -e "-> Building a new (stable or beta) release for the LONG TERM SUPPORT LTS (not for the current latest major version!) <-"
	BUILDING_LATEST_MAJOR_VERSION_STABLE_OR_BETA=0
fi

echo -e "Proceeding..."
sleep 2

############################
echo "Starting build...."
############################


[ -d "$LOCAL_ARCH" ] || mkdir "$LOCAL_ARCH"

cd $BUILD_DIR

if ! [ -d $LOCAL_REPO ]
then
	git clone --config filter.lfs.smudge=true "$URL_REPO" "$LOCAL_REPO"
fi

# we need to exclude LFS files from the upcoming git clone/git checkout,
# unfortunately this git config command does not work...
git config lfs.fetchexclude "tests/"
# ^^ not working, LFS files are fetched below... why?!

echo -e "Working in $LOCAL_REPO"

cd "$LOCAL_REPO"
git checkout master --force
git reset --hard origin/master
git checkout master
git pull
git fetch --tags
echo "checkout repository for tag $VERSION..."

git branch -D "build" > /dev/null 2> /dev/null

echo -e "Commit UI tests git-lfs files to avoid some problems checking out the tag..."
git commit -m'Committing UI tests - nothing relevant to the Piwik package' tests/UI/expected-screenshots/*

echo -e "Now checking out the tag!"
git checkout -b "build" "tags/$VERSION" > /dev/null
[ "$?" -eq "0" ] || die "tag $VERSION does not exist in repository"

# clone submodules that should be in the release
for P in $(git submodule status | egrep $SUBMODULES_PACKAGED_WITH_CORE | awk '{print $2}')
do
	echo -e "cloning submodule $P"
	git submodule update --init $P
done

echo "copying files to a new directory..."
cd ..
[ -d "piwik" ] && rm -rf piwik
cp -pdr "$LOCAL_REPO" piwik
cd piwik

[ "$(git describe --exact-match --tags HEAD)" = "$VERSION" ] || die "could not checkout to the tag for this version, make sure tag exists"

echo "Preparing release $VERSION"
echo "Piwik version in core/Version.php: $(grep "'$VERSION'" core/Version.php)"

[ "$(grep "'$VERSION'" core/Version.php | wc -l)" = "1" ] || die "version $VERSION does not match core/Version.php";

echo "Organizing files and generating manifest file..."
organizePackage

cd ..

echo "packaging release..."
rm "../$LOCAL_ARCH/piwik-$VERSION.zip" 2> /dev/null
zip -r "../$LOCAL_ARCH/piwik-$VERSION.zip" piwik How\ to\ install\ Piwik.html > /dev/null
gpg --armor --detach-sign "../$LOCAL_ARCH/piwik-$VERSION.zip" || die "Failed to sign piwik-$VERSION.zip"

rm "../$LOCAL_ARCH/piwik-$VERSION.tar.gz"  2> /dev/null
tar -czf "../$LOCAL_ARCH/piwik-$VERSION.tar.gz" piwik How\ to\ install\ Piwik.html
gpg --armor --detach-sign "../$LOCAL_ARCH/piwik-$VERSION.tar.gz" || die "Failed to sign piwik-$VERSION.tar.gz"

rm "../$LOCAL_ARCH/piwik-$VERSION-WAG.zip"  2> /dev/null
zip -r "../$LOCAL_ARCH/piwik-$VERSION-WAG.zip" piwik install.sql Manifest.xml parameters.xml > /dev/null 2> /dev/null
gpg --armor --detach-sign "../$LOCAL_ARCH/piwik-$VERSION-WAG.zip" || die "Failed to sign piwik-$VERSION-WAG.zip"


# #### #### #### #### #### #
# let's do the remote work #
# #### #### #### #### #### #

FILES=""
for ext in zip tar.gz
do
	FILES="$FILES ../$LOCAL_ARCH/piwik-$VERSION.$ext ../$LOCAL_ARCH/piwik-$VERSION.$ext.asc"
done

echo ${REMOTE}
scp -p $FILES "${REMOTE}:$REMOTE_HTTP_PATH/"

if [ "$(echo "$VERSION" | grep -E 'rc|b|a|alpha|beta|dev' -i | wc -l)" -eq 1 ]
then
	if [ "$(echo $VERSION | grep -E 'rc|b|beta' -i | wc -l)" -eq 1 ]
	then
		echo -e "Beta or RC release"

		if [ "$BUILDING_LATEST_MAJOR_VERSION_STABLE_OR_BETA" -eq "1" ]
		then
			echo -e "Beta or RC release of the latest Major Piwik release"
			echo $REMOTE_CMD
			$REMOTE_CMD "echo $VERSION > $REMOTE_HTTP_PATH/LATEST_BETA" || die "failed to deploy latest beta version file"

			echo $REMOTE_CMD_API
			$REMOTE_CMD_API "echo $VERSION > $API_PATH/LATEST_BETA" || die "cannot deploy new version file on piwik-api@$REMOTE_SERVER"
		fi

		echo -e "Updating LATEST_${MAJOR_VERSION}X_BETA version on api.piwik.org..."
		echo $REMOTE_CMD_API
		$REMOTE_CMD_API "echo $VERSION > $API_PATH/LATEST_${MAJOR_VERSION}X_BETA" || die "cannot deploy new version file on piwik-api@$REMOTE_SERVER"

	fi
	echo "build finished! http://builds.piwik.org/piwik-$VERSION.zip"
else
	echo "Stable release";

	#linking piwik.org/latest.zip to the newly created build

	if [ "$BUILDING_LATEST_MAJOR_VERSION_STABLE_OR_BETA" -eq "1" ]
	then
		echo -e "Built current latest Piwik major version: creating symlinks on the remote server"
		for name in latest piwik piwik-latest
		do
			for ext in zip tar.gz; do
				$REMOTE_CMD "ln -sf $REMOTE_HTTP_PATH/piwik-$VERSION.$ext $REMOTE_HTTP_PATH/$name.$ext" || die "failed to remotely link $REMOTE_HTTP_PATH/piwik-$VERSION.$ext to $REMOTE_HTTP_PATH/$name.$ext"
				$REMOTE_CMD "ln -sf $REMOTE_HTTP_PATH/piwik-$VERSION.$ext.asc $REMOTE_HTTP_PATH/$name.$ext.asc" || die "failed to remotely link $REMOTE_HTTP_PATH/piwik-$VERSION.$ext/asc to $REMOTE_HTTP_PATH/$name.$ext.asc"
			done
		done

		# record filesize in MB
		SIZE=$(ls -l "../$LOCAL_ARCH/piwik-$VERSION.zip" | awk '/d|-/{printf("%.3f %s\n",$5/(1024*1024),$9)}')

		# upload to builds.piwik.org/LATEST*
		echo $REMOTE_CMD
		$REMOTE_CMD "echo $VERSION > $REMOTE_HTTP_PATH/LATEST" || die "cannot deploy new version file on $REMOTE"
		$REMOTE_CMD "echo $SIZE > $REMOTE_HTTP_PATH/LATEST_SIZE" || die "cannot deploy new archive size on $REMOTE"
		$REMOTE_CMD "echo $VERSION > $REMOTE_HTTP_PATH/LATEST_BETA"  || die "cannot deploy new version file on $REMOTE"

		# upload to piwik.org/LATEST* for the website
		echo $REMOTE_CMD_WWW
		$REMOTE_CMD_WWW "echo $VERSION > $WWW_PATH/LATEST" || die "cannot deploy new version file on piwik@$REMOTE_SERVER"
		$REMOTE_CMD_WWW "echo $SIZE > $WWW_PATH/LATEST_SIZE" || die "cannot deploy new archive size on piwik@$REMOTE_SERVER"


		echo -e "Sending email to Microsoft web team \n\n"
		echo -e "Hello, \n\n\
We are proud to announce a new release for Piwik! \n\
Piwik $VERSION can be downloaded at: http://builds.piwik.org/WebAppGallery/piwik-$VERSION-WAG.zip \n\
SHA1 checksum is: $SHA1_WINDOWS \n\n\
Please consult the changelog for list of closed tickets: http://piwik.org/changelog/ \n\n\
We're looking forward to seeing this Piwik version on Microsoft Web App Gallery. \n\
If you have any question, feel free to ask at feedback@piwik.org. \n\n\
Thank you,\n\n\
Piwik team"
		echo -e "\n----> Send this email 'New Piwik Version $VERSION' to appgal@microsoft.com,hello@piwik.org"

	fi

	# Copy Windows App Gallery release only for stable releases (makes Building betas faster)
	echo $REMOTE
	$REMOTE_CMD "test -d $REMOTE_HTTP_PATH/WebAppGallery || mkdir $REMOTE_HTTP_PATH/WebAppGallery" || die "cannot access the remote server $REMOTE"
	scp -p "../$LOCAL_ARCH/piwik-$VERSION-WAG.zip" "../$LOCAL_ARCH/piwik-$VERSION-WAG.zip.asc" "${REMOTE}:$REMOTE_HTTP_PATH/WebAppGallery/" || die "failed to copy WebAppGalery files"

	SHA1_WINDOWS="$(sha1sum ../$LOCAL_ARCH/piwik-$VERSION-WAG.zip | cut -d' ' -f1)"
	[ -z "$SHA1_WINDOWS" ] && die "cannot compute sha1 hash for ../$LOCAL_ARCH/piwik-$VERSION-WAG.zip"

	echo -e ""

	if [ "$BUILDING_LATEST_MAJOR_VERSION_STABLE_OR_BETA" -eq "1" ]
	then
		echo -e "Updating LATEST and LATEST_BETA versions on api.piwik.org..."
		echo $REMOTE_CMD_API
		$REMOTE_CMD_API "echo $VERSION > $API_PATH/LATEST" || die "cannot deploy new version file on piwik-api@$REMOTE_SERVER"
		$REMOTE_CMD_API "echo $VERSION > $API_PATH/LATEST_BETA" || die "cannot deploy new version file on piwik-api@$REMOTE_SERVER"
	fi

	echo -e "Updating the LATEST_${MAJOR_VERSION}X and  LATEST_${MAJOR_VERSION}X_BETA version on api.piwik.org"
	echo $REMOTE_CMD_API
	$REMOTE_CMD_API "echo $VERSION > $API_PATH/LATEST_${MAJOR_VERSION}X" || die "cannot deploy new version file on piwik-api@$REMOTE_SERVER"
	$REMOTE_CMD_API "echo $VERSION > $API_PATH/LATEST_${MAJOR_VERSION}X_BETA" || die "cannot deploy new version file on piwik-api@$REMOTE_SERVER"

	if [ "$BUILDING_LATEST_MAJOR_VERSION_STABLE_OR_BETA" -eq "1" ]
	then
		echo -e "build finished! http://builds.piwik.org/piwik.zip"
	else
		echo -e "build for LONG TERM SUPPORT version finished! http://builds.piwik.org/piwik-$VERSION.zip"
	fi
fi
