# Makefile for Piwik package construction
#
# If you wish to build the latest stable package, simply type "make builddeb"
# If you need to build a specific version use "PW_VERSION=x.y.z make builddeb"

CURRENT_VERSION	:= $(shell head -1 debian/changelog | sed 's/.*(//;s/).*//;s/-.*//')
CURRENT_FULLV := $(shell head -1 debian/changelog | sed 's/.*(//;s/).*//;')
DEB_ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)


ifndef PW_VERSION
PW_VERSION	:= $(shell wget -qO - https://builds.piwik.org/LATEST)
endif

PW_VERSION_GREATER = $(shell expr $(PW_VERSION) \> $(CURRENT_VERSION))
PW_VERSION_LOWER = $(shell expr $(PW_VERSION) \< $(CURRENT_VERSION))

URL		= https://builds.piwik.org/
ARCHIVE		= piwik-$(PW_VERSION).tar.gz
SIG		= piwik-$(PW_VERSION).tar.gz.asc
FINGERPRINT	= 814E346FA01A20DBB04B6807B5DBD5925590A237

DESTDIR		= /
DIST		= stable
URGENCY		= high

MAKE_OPTS	= -s -w

INSTALL		= /usr/bin/install

.PHONY		: checkfetch fixperms checkversions release checkenv builddeb checkdeb newrelease newversion changelog history clean prepupload upload

# check and optionally fetch the corresponding piwik archive
# from the official server. Uncompress the archive and
# perform additional minor cleanups
checkfetch:
		if [ ! -f "$(ARCHIVE)" ]; then rm -f $(SIG); wget $(URL)/$(ARCHIVE) $(URL)/$(SIG); fi
		gpg --keyserver keys.gnupg.net --recv-keys $(FINGERPRINT)
		gpg --verify $(SIG)
		if [ -d "piwik" ]; then rm -rf "piwik"; fi
		tar -zxf $(ARCHIVE)
		rm -f 'How to install Piwik.html'
		sed -i '/\.gitignore/d' piwik/config/manifest.inc.php
		find piwik/ -type f -name .gitignore -exec rm -f {} \;
		rm -f piwik/misc/translationTool.sh

# fix various file permissions
fixperms:
		find $(DESTDIR) -type d -exec chmod 0755 {} \;
		find $(DESTDIR) -type f -exec chmod 0644 {} \;
		chmod 0755 $(DESTDIR)/usr/share/piwik/misc/cron/archive.sh
		chmod 0755 $(DESTDIR)/usr/share/piwik/console
		chmod 0755 $(DESTDIR)/usr/share/piwik/vendor/leafo/lessphp/lessify
		chmod 0755 $(DESTDIR)/usr/share/piwik/vendor/leafo/lessphp/package.sh
		chmod 0755 $(DESTDIR)/usr/share/piwik/vendor/leafo/lessphp/plessc
		chmod 0755 $(DESTDIR)/usr/share/piwik/misc/composer/build-xhprof.sh
		chmod 0755 $(DESTDIR)/usr/share/piwik/misc/composer/clean-xhprof.sh

# check lintian licenses so we can remove obsolete ones
checklintianlic:
	@for F in $(shell cat debian/lintian.rules | grep extra-license-file | awk '{print $$3}') ; do \
		echo -n "  * checking: $$F"; \
		if [ ! -f "$(DESTDIR)/$$F" ]; then \
			echo " missing."; \
			echo "1" >&2; \
		else \
			echo " ok."; \
		fi; \
	done 3>&2 2>&1 1>&3 | grep --silent "1" && exit 1 || echo >/dev/null

# check lintian licenses so we can remove obsolete ones
checklintianextralibs:
	@for F in $(shell cat debian/lintian.rules | grep -e embedded-javascript-library -e embedded-php-library | awk '{print $$3}') ; do \
		echo -n "  * checking: $$F"; \
		if [ ! -f "$(DESTDIR)/$$F" ]; then \
			echo " missing."; \
			echo "1" >&2; \
		else \
			echo " ok."; \
		fi; \
	done 3>&2 2>&1 1>&3 | grep --silent "1" && exit 1 || echo >/dev/null

# raise an error if the building version is lower that the head of debian/changelog
checkversions:
ifeq "$(PW_VERSION_LOWER)" "1"
	@echo "The version you're trying to build is older that the head of your changelog."
	@exit 1
endif

# create a new release either major or minor.
release:	checkenv checkversions
ifeq "$(PW_VERSION_GREATER)" "1"
		$(MAKE) newrelease
		$(MAKE) history
else
		$(MAKE) newversion
endif
		debchange --changelog debian/changelog --release ''
		$(MAKE) builddeb
		$(MAKE) checkdeb

# check if the local environment is suitable to generate a package
# we check environment variables and a gpg private key matching
# these variables. this is necessary as we sign our packages.
checkenv:
ifndef DEBEMAIL
		echo "Missing environment variable DEBEMAIL"
		@exit 1
endif
ifndef DEBFULLNAME
		echo "Missing environment variable DEBFULLNAME"
		@exit 1
endif
		gpg --list-secret-keys "$(DEBFULLNAME) <$(DEBEMAIL)>" >/dev/null

# creates the .deb package and other related files
# all files are placed in ../
builddeb:	checkenv checkversions
		dpkg-buildpackage -i '-Itmp' -I.git -I$(ARCHIVE) -rfakeroot

# check the generated .deb for consistency
# the filename is determines by the 1st line of debian/changelog
checkdeb:
		lintian --color auto -v -i  ../`parsechangelog | grep ^Source | awk '{print $$2}'`_`parsechangelog | grep ^Version | awk '{print $$2}'`_*.deb

# create a new release based on PW_VERSION variable
newrelease:
		debchange --changelog debian/changelog --urgency high --newversion $(PW_VERSION)-1 "Releasing Piwik $(PW_VERSION)"

# creates a new version in debian/changelog
newversion:
		debchange --changelog debian/changelog -i --urgency $(URGENCY)

# allow user to enter one or more changelog comment manually
changelog:
		debchange --changelog debian/changelog --force-distribution $(DIST) --urgency $(URGENCY) -r
		debchange --changelog debian/changelog -a 

# fetch the history and add it to the debian/changelog
history:
		bash debian/scripts/history.sh $(PW_VERSION)

# clean for any previous / unwanted files from previous build
clean:
		rm -rf piwik
		rm -f piwik-*.tar.gz piwik-*.tar.gz.asc
		rm -rf debian/piwik

upload:
		test ! -f ../piwik_$(CURRENT_FULLV)_all.deb || mv ../piwik_$(CURRENT_FULLV)_all.deb $(CURDIR)/tmp
		test ! -f ../piwik_$(CURRENT_FULLV).dsc || mv ../piwik_$(CURRENT_FULLV).dsc $(CURDIR)/tmp
		test ! -f ../piwik_$(CURRENT_FULLV)_$(DEB_ARCH).changes || mv ../piwik_$(CURRENT_FULLV)_$(DEB_ARCH).changes $(CURDIR)/tmp
		test ! -f ../piwik_$(CURRENT_FULLV).tar.gz || mv ../piwik_$(CURRENT_FULLV).tar.gz $(CURDIR)/tmp
		dupload --to piwik $(CURDIR)/tmp/piwik_$(CURRENT_FULLV)_$(DEB_ARCH).changes
