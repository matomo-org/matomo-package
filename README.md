# Piwik Package 

This repository contains:

* Piwik release script (official package), 
* and Debian/Ubuntu package (allows sysadmins to deploy Piwik within seconds using `apt-get install piwik -V`) 

## Debian Package

 * [debian/Readme.debian](https://github.com/piwik/piwik-package/blob/master/debian/README.Debian#readme) - How to use the Debian package and setup Piwik on your Debian server.
 * [debian/Readme.md](https://github.com/piwik/piwik-package/tree/master/debian#readme) - Guide for Piwik staff in charge of generating the Debian package. System administrators may also be interested in this documentation.

## Core Piwik Package

To generate a new Piwik release for example 3.0.0-b1, follow these steps:
 
* Edit `core/Version.php` and set the correct version number
* Check that the CI builds is green
* Create a release on Github which will automatically create a git tag.
* Then package the release. Run: `./scripts/build.sh 3.0.0-b1`. This script will:
  * the first time it runs it clones the Piwik git repository.
  * then it builds the package, removing any un-necessary files, 
  * then it uploads the `.zip` and `.tar.gz` packages to https://builds.piwik.org
* The new Piwik version is now shipped to users worldwide,
 * Users will now notified in their Administration area, and some users will receive email alerts about the new version.

