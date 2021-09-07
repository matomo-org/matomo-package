# Matomo Package 

This repository contains the Matomo release script (official package).

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

