# Very basic Makefile

URL		= http://builds.piwik.org/
PW_VERSION	= 1.12
ARCHIVE		= piwik-$(PW_VERSION).tar.gz

DESTDIR		= /
DIST		= stable
URGENCY		= high

MAKE_OPTS	= -s -w

INSTALL		= /usr/bin/install

ETC_OBJ		= 

.PHONY		: install checkfetch

checkfetch:
		if [ ! -f "$(ARCHIVE)" ]; then wget $(URL)/$(ARCHIVE); fi
		if [ ! -d "piwik" ]; then tar -zxf $(ARCHIVE); fi
		rm -f "How to install Piwik.html"

fixperms:
		find $(DESTDIR) -type d -exec chmod 0755 {} \;
		find $(DESTDIR) -type f -exec chmod 0644 {} \;
		chmod 0755 $(DESTDIR)/usr/share/piwik/misc/cron/archive.sh

removelicences:
		rm $(DESTDIR)/usr/share/piwik/js/LICENSE.txt
		rm $(DESTDIR)/usr/share/piwik/plugins/SecurityInfo/LICENSE
		rm $(DESTDIR)/usr/share/piwik/plugins/ExampleUI/images/icons-planet/LICENSE
		rm $(DESTDIR)/usr/share/piwik/libs/PiwikTracker/LICENSE.txt
		rm $(DESTDIR)/usr/share/piwik/libs/jquery/MIT-LICENSE-history.txt
		rm $(DESTDIR)/usr/share/piwik/libs/jquery/MIT-LICENSE-jqueryui.txt
		rm $(DESTDIR)/usr/share/piwik/libs/jquery/MIT-LICENSE-placeholder.txt
		rm $(DESTDIR)/usr/share/piwik/libs/jquery/MIT-LICENSE-jquery.txt
		rm $(DESTDIR)/usr/share/piwik/libs/jquery/MIT-LICENSE-scrollto.txt
		rm $(DESTDIR)/usr/share/piwik/libs/jquery/LICENSE-sizzle.txt
		rm $(DESTDIR)/usr/share/piwik/libs/jqplot/MIT-LICENSE.txt
		rm $(DESTDIR)/usr/share/piwik/libs/cssmin/MIT-LICENSE.txt
		rm $(DESTDIR)/usr/share/piwik/libs/Zend/LICENSE.txt
		rm $(DESTDIR)/usr/share/piwik/libs/PEAR/LICENSE
		rm $(DESTDIR)/usr/share/piwik/libs/sparkline/LICENSE-BSD.txt

builddeb:
		dpkg-buildpackage -i -I -rfakeroot -ai386

checkdeb:
		lintian --color auto -v -i  ../`parsechangelog | grep ^Source | awk '{print $$2}'`_`parsechangelog | grep ^Version | awk '{print $$2}'`_*.deb

newversion:
		debchange --changelog debian/changelog -i --urgency $(URGENCY)

changelog:
		debchange --changelog debian/changelog --force-distribution $(DIST) --urgency $(URGENCY) -r
		debchange --changelog debian/changelog -a 

clean:
		rm -rf $(ARCHIVE)
		rm -rf piwik
