# set and uncomment the cron as you like
# .---------------- minute (0 - 59)
# | .-------------- hour (0 - 23)
# | |	.---------- day of month (1 - 31)
# | |	| .-------- month (1 - 12) OR jan,feb,mar,apr ...
# | |	| | .------ day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# | |	| | |
# * *	* * *	user-name       command to be executed
# 5 *	* * *	www-data        [ -e /usr/share/piwik/misc/cron/archive.php ] && [ -x /usr/bin/php ] && /usr/bin/php /usr/share/piwik/misc/cron/archive.php -- "url=http://example.org/piwik/" >/dev/null 2>&1
