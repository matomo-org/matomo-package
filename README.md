# Debian package for Piwik

## Description

This repository contains the required skeleton to create your own debian package for piwik.

## Pre-requisites

You need to install the following packages

  * lintian
  * devscripts

You also need (optional)

  * A valid GPG key to sign your package, set with your email address (to sign the generated package)
  * The env variable "DEBEMAIL" set with your email address (to update the changelog)
  * The env variable "DEBFULLNAME" set with your full name (to update the changelog)

## Package

### unsigned package

  * dpkg-buildpackage -ai386 -us -uc -rfakeroot
  * then the resulting package will be stored one directory above

### signed package

You may want to sign your package is you maintain your own debian repository.

  * make builddeb
  * then the resulting package will be stored one directory above

### Verify the package

You may want to check the package for consistency and other warning.

  * make checkdeb
  * lintian will display errors and warnings if any

# Background history

I needed to install piwik on a Debian server for a client. I found Fabrizio work but sadly this didn't work with the latest piwik (1.12) version. So, as I maintain my own internal package repository, I decided to adapt his work and create a true vanilla version of Piwik for Debian. I also tried my best to ensure a good security level (files owned by 'root', configs in '/etc/piwik' and generated files in '/var/lib/piwik/').

Some Debian purist may scream at me for all the lintian rules, licenses files and other problems. The idea is not to submit my work to the Debian project, but at least offer an interim for people willing to maintain their Piwik installation via a proper package.

# Credits

  * Main credit goes to the piwik team for their fantastic job
  * All people contributing to the Piwik project and the funders
  * Fabrizio Regalli and the Debian team for some of the files I reused and adapted (see debian/copyright)

