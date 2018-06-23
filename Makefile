# Makefile for Matomo (Piwik) package construction
#
# This is what you mostly need to know about this Makefile
# * make newversion: Prompt to create a new package version
# * make changfelog: Prompt to enter a new chanbgelog entry in debian/changelog
# * make builddeb: To rebuild your debian package. debian/changelog is not updated
# * make checkdeb: To check the package compliance using lintian
# * make upload: To upload your debian package
# * make commitrelease: To commit your debian/changelog

CURRENT_VERSION	:= $(shell head -1 debian/changelog | sed 's/.*(//;s/).*//;s/-.*//')
DEB_ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)

ifndef DEB_VERSION
DEB_VERSION := $(shell head -n 1 debian/changelog | sed 's/.*(//;s/).*//;')
endif

ifndef DEB_STATUS
DEB_STATUS := $(shell head -n 1 debian/changelog | awk '{print $$3}' | sed 's/;//g')
endif

DESTDIR		= /
DIST		= stable
URGENCY		= high

MAKE_OPTS	= -s

INSTALL		= /usr/bin/install

.PHONY		: checkversions checkenv builddeb checkdeb newrelease newversion changelog clean upload

RED		= \033[0;31m
GREEN		= \033[0;32m
NC		= \033[0m

# raise an error if the building version is lower that the head of debian/changelog
checkversions:
ifeq "$(RELEASE_VERSION_LOWER)" "1"
	@echo "$(RED)The version you're trying to build is older that the head of your changelog.$(NC)"
	@exit 1
endif

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
		dpkg-buildpackage -i '-Itmp' -I.git -rfakeroot


# check the generated .deb for consistency
# the filename is determines by the 1st line of debian/changelog
checkdeb:
		@echo " [LINTIAN] Checking package(s)..."
		@for P in $(shell cat debian/control | grep ^Package | awk '{print $$2}'); do \
			lintian --no-tag-display-limit --color auto -L '>=important' -v -i ../$${P}_$(shell parsechangelog | grep ^Version | awk '{print $$2}')_*.deb; \
		done

# creates a new version in debian/changelog
newversion:
		@debchange --changelog debian/changelog -i --urgency $(URGENCY)
		@debchange --changelog debian/changelog --force-distribution $(DIST) --urgency $(URGENCY) -r

# allow user to enter one or more changelog comment manually
changelog:
		@debchange --changelog debian/changelog --force-distribution $(DIST) --urgency $(URGENCY) -r
		@debchange --changelog debian/changelog -a

# clean for any previous / unwanted files from previous build
clean:
		@echo " [RM] matomo/ debian/tmp/ debian/matomo/ debian/piwik/"
		@rm -rf matomo debian/tmp debian/matomo debian/piwik/

distclean:	clean
		@echo " [RM] matomo-*.tar.gz matomo-*.tar.gz.asc matomo-*.zip matomo-*.zip.asc"
		@rm -f matomo-*.tar.gz matomo-*.tar.gz.asc matomo-*.zip matomo-*.zip.asc

prepupload:
		@echo " [MKDIR] tmp/"
		@test -d tmp || mkdir tmp
		@test ! -f ../piwik_$(DEB_VERSION)_all.deb || echo " [MV] ../piwik_$(DEB_VERSION)_all.deb => tmp/"
		@test ! -f ../piwik_$(DEB_VERSION)_all.deb || mv ../piwik_$(DEB_VERSION)_all.deb $(CURDIR)/tmp/
		@test ! -f ../piwik_$(DEB_VERSION).dsc || echo " [MV] ../piwik_$(DEB_VERSION).dsc => tmp/"
		@test ! -f ../piwik_$(DEB_VERSION).dsc || mv ../piwik_$(DEB_VERSION).dsc $(CURDIR)/tmp/
		@test ! -f ../piwik_$(DEB_VERSION)_$(DEB_ARCH).changes || echo " [MV] ../piwik_$(DEB_VERSION)_$(DEB_ARCH).changes => tmp/"
		@test ! -f ../piwik_$(DEB_VERSION)_$(DEB_ARCH).changes || mv ../piwik_$(DEB_VERSION)_$(DEB_ARCH).changes $(CURDIR)/tmp/
		@test ! -f ../piwik_$(DEB_VERSION).tar.gz || echo " [MV] ../piwik_$(DEB_VERSION).tar.gz => tmp/"
		@test ! -f ../piwik_$(DEB_VERSION).tar.gz || mv ../piwik_$(DEB_VERSION).tar.gz $(CURDIR)/tmp/
		@test ! -f ../piwik_$(DEB_VERSION)_$(DEB_ARCH).buildinfo || echo " [MV] ../piwik_$(DEB_VERSION)_$(DEB_ARCH).buildinfo => tmp/"
		@test ! -f ../piwik_$(DEB_VERSION)_$(DEB_ARCH).buildinfo || mv ../piwik_$(DEB_VERSION)_$(DEB_ARCH).buildinfo $(CURDIR)/tmp/

upload:		prepupload
		@echo " [UPLOAD] => to matomo"
		@dupload --quiet --to matomo $(CURDIR)/tmp/piwik_$(DEB_VERSION)_$(DEB_ARCH).changes

commitrelease:
		@echo " [GIT] Commit release"
		@./debian/scripts/githelp.sh commitrelease
