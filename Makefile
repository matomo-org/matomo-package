# Makefile for Matomo (Piwik) package construction
#
# This is what you mostly need to know about this Makefile
# * make release: When a new release has been published
# * make upload: To upload your debian package
# * make commitrelease: To commit your debian/changelog
# * make builddeb: To rebuild your debian package. debian/changelog is not updated
# * make checkdeb: To check the package compliance using lintian
#
# Options are:
# * RELEASE_VERSION=x.y.z Specify which package version you want to build

URL		= https://builds.matomo.org
FINGERPRINT	= 814E346FA01A20DBB04B6807B5DBD5925590A237

CURRENT_VERSION	:= $(shell head -1 debian/changelog | sed 's/.*(//;s/).*//;s/-.*//')
DEB_ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)

ifndef DEB_VERSION
DEB_VERSION := $(shell head -n 1 debian/changelog | sed 's/.*(//;s/).*//;')
endif

ifndef DEB_STATUS
DEB_STATUS := $(shell head -n 1 debian/changelog | awk '{print $$3}' | sed 's/;//g')
endif

ifndef RELEASE_VERSION
RELEASE_VERSION	:= $(shell wget --no-cache -qO - $(URL)/LATEST)
endif

RELEASE_VERSION_GREATER = $(shell ./debian/scripts/vercomp.sh $(RELEASE_VERSION) $(CURRENT_VERSION))
RELEASE_VERSION_LOWER = $(shell ./debian/scripts/vercomp.sh $(RELEASE_VERSION) $(CURRENT_VERSION))

ifndef PW_ARCHIVE_EXT
PW_ARCHIVE_EXT	:= $(shell wget --no-cache -q --spider $(URL)/matomo-$(RELEASE_VERSION).tar.gz && echo 'tar.gz' || echo 'zip' )
endif

ARCHIVE		= matomo-$(RELEASE_VERSION).$(PW_ARCHIVE_EXT)
SIG		= matomo-$(RELEASE_VERSION).$(PW_ARCHIVE_EXT).asc

DESTDIR		= /
DIST		= stable
URGENCY		= high

MAKE_OPTS	= -s

INSTALL		= /usr/bin/install

.PHONY		: checkfetch fixperms checkversions release checkenv builddeb checkdeb newrelease newversion changelog history clean upload fixsettings

RED		= \033[0;31m
GREEN		= \033[0;32m
NC		= \033[0m

# check and optionally fetch the corresponding matomo archive
# from the official server. Uncompress the archive and
# perform additional minor cleanups
checkfetch:
		@echo -n " [WGET] ... "
		@if [ ! -f "$(SIG)" ]; then echo -n "$(URL)/$(SIG) "; wget --no-cache -q $(URL)/$(SIG); fi;
		@if [ ! -f "$(ARCHIVE)" ]; then echo -n "$(URL)/$(ARCHIVE) "; wget --no-cache -q $(URL)/$(ARCHIVE); fi;
		@echo "done."
		@gpgconf --kill dirmngr
		@test ! -z "$(shell gpg2 --list-keys | grep $(FINGERPRINT))" || gpg2 --keyserver keys.gnupg.net --recv-keys $(FINGERPRINT)
		@echo " [GPG] verify $(FINGERPRINT)" && gpg --verify $(SIG)
		@echo " [RM] matomo/" && if [ -d "matomo" ]; then rm -rf "matomo"; fi
		@echo " [UNPACK] $(ARCHIVE)"
		@test "$(PW_ARCHIVE_EXT)" != "zip" || unzip -qq $(ARCHIVE)
		@test "$(PW_ARCHIVE_EXT)" != "tar.gz" || tar -zxf $(ARCHIVE)

# perform some cleanup tasks to remove extraneous files
# from the built package. Some (js)libs are dragged with
# examples and extra material that aren't required in the
# final package
cleanup:
		@echo " [RM] Cleanup: vcs, ci"
		@rm -f 'How to install Matomo.html'
		@find matomo/ -type f -name .gitignore -exec rm -f {} \;
		@find matomo/ -type f -name .gitattributes -exec rm -f {} \;
		@find matomo/ -type f -name .gitmodules -exec rm -f {} \;
		@find matomo/ -type f -name .git -exec rm -f {} \;
		@find matomo/ -type f -name .gitkeep -exec rm -f {} \;
		@find matomo/ -type f -name .editorconfig -exec rm -f {} \;
		@find matomo/ -type f -name .travis.yml -exec rm -f {} \;
		@find matomo/ -type f -name .travis.sh -exec rm -f {} \;
		@find matomo/ -type f -name .coveralls.yml -exec rm -f {} \;
		@find matomo/ -type f -name .jshintrc -exec rm -f {} \;
		@find matomo/ -type f -name .scrutinizer.yml -exec rm -f {} \;
		@find matomo/ -type f -name "*bower.json" -exec rm -f {} \;
		@rm -rf matomo/vendor/doctrine/cache/.git
		@rm -f matomo/misc/translationTool.sh
		@echo " [RM] Cleanup: jScrollPane"
		@rm -rf matomo/libs/bower_components/jScrollPane/issues
		@rm -f matomo/libs/bower_components/jScrollPane/ajax_content.html
		@rm -f matomo/libs/bower_components/jScrollPane/script/demo.js
		@rm -f matomo/libs/bower_components/jScrollPane/themes/lozenge/index.html
		@grep -li demo matomo/libs/bower_components/jScrollPane/*.html | while read F; do rm -f $$F; done;
		@echo " [RM] Cleanup: bower_components"
		@rm -f matomo/libs/bower_components/jquery-placeholder/demo.html


checkconfig:
		@echo -n " [CONF] Checking configuration files... "
		@if [ "$(shell cat debian/matomo.install | grep "^matomo/config/" | wc -l)" -ne "$(shell find ./matomo/config/ -type f | wc -l)" ]; then \
			echo "\n $(RED)[CONF]$(NC) Configuration files may have been added or removed, please update debian/matomo.install"; \
			echo "          $(shell cat debian/matomo.install | grep "^matomo/config/" | wc -l)" -ne "$(shell find ./matomo/config/ -type f | wc -l)" "$(shell pwd)"; \
			exit 1; \
		fi
		@echo "done"

manifest:
		@if [ -z "$(DESTDIR)" ]; then echo "$(RED)missing DESTDIR=$(NC)"; exit 1; fi
		@echo -n " [MANIFEST] Generating manifest.inc.php... "
		@rm -f $(DESTDIR)/etc/matomo/manifest.inc.php
		@find $(DESTDIR)/ -type f -printf '%s ' -exec md5sum {} \; \
			| grep -v "user/.htaccess" \
			| grep -v "$(DESTDIR)/DEBIAN/" \
			| grep -v "$(DESTDIR)/usr/share/doc/matomo/" \
			| grep -v "$(DESTDIR)/usr/share/matomo/README" \
			| grep -v "$(DESTDIR)/usr/share/lintian/" \
			| grep -v "$(DESTDIR)/etc/cron.d" \
			| grep -v "$(DESTDIR)/etc/logrotate.d" \
			| grep -v "$(DESTDIR)/etc/matomo/lighttpd.conf" \
			| grep -v "$(DESTDIR)/etc/matomo/apache.conf" \
			| grep -v "$(DESTDIR)/etc/apt/" \
			| egrep -v 'manifest.inc.php|autoload.php|autoload_real.php' \
			| sed 's#$(DESTDIR)##g;' \
			| sed 's#/usr/share/matomo/##g; s#/etc/matomo/#config/#g;' \
			| sed '1,$$ s/\([0-9]*\) \([a-z0-9]*\)  \(.*\)/\t\t"\3" => array("\1", "\2"),/;' \
			| sort \
			| sed '1 s/^/<?php\n\/\/ This file is automatically generated during the Matomo build process\nnamespace Piwik;\nclass Manifest {\n\tstatic $$files=array(\n/; $$ s/$$/\n\t);\n}/' \
			> $(DESTDIR)/etc/matomo/manifest.inc.php
		@echo "$(GREEN)done$(NC)."
		@echo -n " [MANIFEST] Checking manifest.inc.php syntax... "
		@php -l $(DESTDIR)/etc/matomo/manifest.inc.php >/dev/null
		@echo "$(GREEN)done$(NC)."
		@echo -n " [MANIFEST] Checking for unexpected entries in manifest.inc.php... "
		@if [ ! -z "$(shell grep '"/' $(DESTDIR)/etc/matomo/manifest.inc.php)" ]; then echo "$(RED)check $(DESTDIR)/etc/matomo/manifest.inc.php for extra entries$(NC)"; exit 1; fi;
		@echo "$(GREEN)done$(NC)."


fixsettings:
		@echo " [SED] Configuration adjustments"
		@sed -i '/\.gitignore/d' $(DESTDIR)/etc/matomo/manifest.inc.php
		@sed -i 's/^\(enable_auto_update\).*/\1 = 0/g;' $(DESTDIR)/etc/matomo/global.ini.php

# fix various file permissions
fixperms:
		@echo -n " [CHMOD] Fixing permissions... "
		@find $(DESTDIR) -type d -not -path "$(DESTDIR)/DEBIAN" -exec chmod 0755 {} \;
		@find $(DESTDIR) -type f -not -path "$(DESTDIR)/DEBIAN/*" -exec chmod 0644 {} \;
		@chmod 0755 $(DESTDIR)/usr/share/matomo/misc/cron/archive.sh
		@chmod 0755 $(DESTDIR)/usr/share/matomo/console
		@chmod 0755 $(DESTDIR)/usr/share/matomo/vendor/leafo/lessphp/lessify
		@chmod 0755 $(DESTDIR)/usr/share/matomo/vendor/leafo/lessphp/package.sh
		@chmod 0755 $(DESTDIR)/usr/share/matomo/vendor/leafo/lessphp/plessc
		@chmod 0755 $(DESTDIR)/usr/share/matomo/misc/composer/build-xhprof.sh
		@chmod 0755 $(DESTDIR)/usr/share/matomo/misc/composer/clean-xhprof.sh
		@chmod 0755 $(DESTDIR)/usr/share/matomo/vendor/pear/archive_tar/sync-php4
		@chmod 0755 $(DESTDIR)/usr/share/matomo/vendor/tecnickcom/tcpdf/tools/tcpdf_addfont.php
		@echo "done."

# check lintian licenses so we can remove obsolete ones
checklintianlic:
	@echo " [DEB] Checking extra license files presence"
	@for F in $(shell cat debian/matomo.lintian-overrides | grep extra-license-file | awk '{print $$3}') ; do \
		echo -n "  * checking: $$F"; \
		if [ ! -f "$(DESTDIR)/$$F" ]; then \
			echo " $(RED)missing$(NC)."; \
			echo "1" >&2; \
		else \
			echo " $(GREEN)ok$(NC)."; \
		fi; \
	done 3>&2 2>&1 1>&3 | grep --silent "1" && exit 1 || echo >/dev/null

# check lintian licenses so we can remove obsolete ones
checklintianextralibs:
	@echo " [DEB] Checking for extra libs presence"
	@for F in $(shell cat debian/matomo.lintian-overrides | grep -e embedded-javascript-library -e embedded-php-library | awk '{print $$3}') ; do \
		echo -n "  * checking: $$F"; \
		if [ ! -f "$(DESTDIR)/$$F" ]; then \
			echo " $(RED)missing$(NC)."; \
			echo "1" >&2; \
		else \
			echo " $(GREEN)ok$(NC)."; \
		fi; \
	done 3>&2 2>&1 1>&3 | grep --silent "1" && exit 1 || echo >/dev/null

# raise an error if the building version is lower that the head of debian/changelog
checkversions:
ifeq "$(RELEASE_VERSION_LOWER)" "1"
	@echo "$(RED)The version you're trying to build is older that the head of your changelog.$(NC)"
	@exit 1
endif

# create a new release either major or minor.
release:	checkenv checkversions
ifeq "$(RELEASE_VERSION_GREATER)" "2"
		@$(MAKE) newrelease
		@$(MAKE) history
else
		@$(MAKE) newversion
endif
		@debchange --changelog debian/changelog --release ''
		@$(MAKE) builddeb
		@$(MAKE) checkdeb

# check if the local environment is suitable to generate a package
# we check environment variables and a gpg private key matching
# these variables. this is necessary as we sign our packages.
checkenv:
ifndef DEBEMAIL
		@echo " [ENV] Missing environment variable DEBEMAIL"
		@exit 1
endif
ifndef DEBFULLNAME
		@echo " [ENV] Missing environment variable DEBFULLNAME"
		@exit 1
endif
		@echo " [GPG] Checking environment"
		@gpg2 --list-secret-keys "$(DEBFULLNAME) <$(DEBEMAIL)>" >/dev/null

# creates the .deb package and other related files
# all files are placed in ../
builddeb:	checkenv checkversions
		@echo -n " [PREP] Checking package status..."
ifeq "$(DEB_STATUS)" "UNRELEASED"
		@echo " $(RED)The package changelog marks the package as 'UNRELEASED'.$(NC)"
		@echo "        $(RED)run this command: debchange --changelog debian/changelog --release ''$(NC)"
		@exit 1
else
		@echo "$(GREEN)ok$(NC)."
endif

		@echo " [DPKG] Building packages..."
		dpkg-buildpackage -i '-Itmp' -I.git -I$(ARCHIVE) -rfakeroot


# check the generated .deb for consistency
# the filename is determines by the 1st line of debian/changelog
checkdeb:
		@echo " [LINTIAN] Checking package(s)..."
		@for P in $(shell cat debian/control | grep ^Package | awk '{print $$2}'); do \
			lintian --no-tag-display-limit --color auto -L '>=important' -v -i ../$${P}_$(shell parsechangelog | grep ^Version | awk '{print $$2}')_*.deb; \
		done

# create a new release based on RELEASE_VERSION variable
newrelease:
		@debchange --changelog debian/changelog --urgency $(URGENCY) --package $(shell cat debian/control | grep ^Source | awk '{print $$2}') --newversion $(RELEASE_VERSION)-1 "Releasing Matomo $(RELEASE_VERSION)"

# creates a new version in debian/changelog
newversion:
		@debchange --changelog debian/changelog -i --urgency $(URGENCY)
		@debchange --changelog debian/changelog --force-distribution $(DIST) --urgency $(URGENCY) -r

# allow user to enter one or more changelog comment manually
changelog:
		@debchange --changelog debian/changelog --force-distribution $(DIST) --urgency $(URGENCY) -r
		@debchange --changelog debian/changelog -a

# fetch the history and add it to the debian/changelog
history:
		@bash debian/scripts/history.sh $(RELEASE_VERSION)

# clean for any previous / unwanted files from previous build
clean:
		@echo " [RM] matomo/ debian/tmp/ debian/matomo/"
		@rm -rf matomo debian/tmp debian/matomo

distclean:	clean
		@echo " [RM] matomo-*.tar.gz matomo-*.tar.gz.asc matomo-*.zip matomo-*.zip.asc"
		@rm -f matomo-*.tar.gz matomo-*.tar.gz.asc matomo-*.zip matomo-*.zip.asc

prepupload:
		@echo " [MKDIR] tmp/"
		@test -d tmp || mkdir tmp
		@test ! -f  $(ARCHIVE) || echo " [MV] $(ARCHIVE) => tmp/"
		@test ! -f  $(ARCHIVE) || mv $(ARCHIVE) tmp/
		@test ! -f  $(SIG) || echo " [MV] $(SIG) => tmp/"
		@test ! -f  $(SIG) || mv $(SIG) tmp/
		@test ! -f ../matomo_$(DEB_VERSION)_all.deb || echo " [MV] ../matomo_$(DEB_VERSION)_all.deb => tmp/"
		@test ! -f ../matomo_$(DEB_VERSION)_all.deb || mv ../matomo_$(DEB_VERSION)_all.deb $(CURDIR)/tmp/
		@test ! -f ../matomo_$(DEB_VERSION).dsc || echo " [MV] ../matomo_$(DEB_VERSION).dsc => tmp/"
		@test ! -f ../matomo_$(DEB_VERSION).dsc || mv ../matomo_$(DEB_VERSION).dsc $(CURDIR)/tmp/
		@test ! -f ../matomo_$(DEB_VERSION)_$(DEB_ARCH).changes || echo " [MV] ../matomo_$(DEB_VERSION)_$(DEB_ARCH).changes => tmp/"
		@test ! -f ../matomo_$(DEB_VERSION)_$(DEB_ARCH).changes || mv ../matomo_$(DEB_VERSION)_$(DEB_ARCH).changes $(CURDIR)/tmp/
		@test ! -f ../matomo_$(DEB_VERSION).tar.gz || echo " [MV] ../matomo_$(DEB_VERSION).tar.gz => tmp/"
		@test ! -f ../matomo_$(DEB_VERSION).tar.gz || mv ../matomo_$(DEB_VERSION).tar.gz $(CURDIR)/tmp/
		@test ! -f ../matomo_$(DEB_VERSION)_$(DEB_ARCH).buildinfo || echo " [MV] ../matomo_$(DEB_VERSION)_$(DEB_ARCH).buildinfo => tmp/"
		@test ! -f ../matomo_$(DEB_VERSION)_$(DEB_ARCH).buildinfo || mv ../matomo_$(DEB_VERSION)_$(DEB_ARCH).buildinfo $(CURDIR)/tmp/

upload:		prepupload
		@echo " [UPLOAD] => to matomo"
		@dupload --quiet --to matomo $(CURDIR)/tmp/matomo_$(DEB_VERSION)_$(DEB_ARCH).changes

commitrelease:
		@echo " [GIT] Commit release"
		@./debian/scripts/githelp.sh commitrelease
