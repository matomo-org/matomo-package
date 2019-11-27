# Matomo Package 

This repository contains:

* Matomo release script (official package), 
* and Debian/Ubuntu package (allows sysadmins to deploy Matomo within seconds using `apt-get install matomo -V`) 

## Debian Package

 * [debian/Readme.debian](https://github.com/matomo-org/matomo-package/blob/master/debian/README.Debian#readme) - How to use the Debian package and setup Matomo on your Debian server.
 * [debian/Readme.md](https://github.com/matomo-org/matomo-package/tree/master/debian#readme) - Guide for Matomo staff in charge of generating the Debian package. System administrators may also be interested in this documentation.

## Core Matomo Package

To generate a new Matomo release for example 3.0.0-b1, follow these steps:
 
* Edit `core/Version.php` and set the correct version number
* Check that the CI builds is green
* Create a release on Github which will automatically create a git tag.
* Then package the release. Run: `./scripts/build.sh 3.0.0-b1`. This script will:
  * the first time it runs it clones the Matomo git repository.
  * then it builds the package, removing any un-necessary files, 
  * then it uploads the `.zip` and `.tar.gz` packages to https://builds.matomo.org
* The new Matomo version is now shipped to users worldwide,
 * Users will now notified in their Administration area, and some users will receive email alerts about the new version.

## Multiple gpg keys
To choose a default key without having to specify --default-key on the command-line every time, create a configuration file (if it doesn't already exist), `~/.gnupg/gpg.conf` and add a line containing

`default-key 5590A237`

