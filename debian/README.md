# Debian package for Piwik

## Audience

This documentation is primarily for Piwik staff in charge of generating the Debian package. System administrators may also be interested in this documentation.

## Description

This repository contains the required skeleton to create your own Debian package for Piwik.

## Pre-requisites

You need to install the following packages

  * lintian
  * devscripts
  * debhelper
  * dupload

You also need

  * A valid GPG key to sign your package, set with your email address (to sign the generated package)
  * Your valid and current GPG must have been inserted into the server keyring
  * The env variable ``DEBEMAIL`` set with your email address (to update the changelog)
  * The env variable ``DEBFULLNAME`` set with your full name (to update the changelog)
  * Please note that ``DEBFULLNAME``, ``DEBEMAIL`` and the details of your GPG key must match
  * A valid "dupload" rule named "piwik" to upload your file on the official server
  * Your public ssh key installed and enabled on the production server

## Package

The process has been designed to be as simple as possible. Though, manual intervention may be required from time to time. Seek help of an experienced sysadmin if you have any doubts.

### New release

The ``release`` rule will generate, sign and verify your package.

  * ``make release``

If no errors were reported, you should be fine to send your package for immediate publication

  * ``make upload``

### Resuming a release

If ``make newrelease`` has been interrupted, check and fix the error(s). Then, you can resume the process with the command below.

  * ``make buildddeb``

### Manual package verification

You may want to check the package for consistency and other warning. This step is part of ``make release``

  * ``make checkdeb``
  * lintian will display errors and warnings if any

Please note that a package shouldn't be uploaded if errors or warnings remain.

### New release upload

Once "dupload" has been configured and a rule named "piwik" is present, just type:

  * ``make upload``

### Intermediate versions

Once in a while it might be necessary to fixes minor details associated to the package.

  * ``make newversion``

    It will create a new intermediate version in ``debian/changelog``.

  * ``make changelog``

    If you need to edit ``debian/changelog``. This also update the date and time of the latest entry.

  * ``make builddeb``

    This will build and sign your Debian package.

  * ``make checkdeb``

    Check your package and displays errors and warnings if any.

  * ``make upload``

    Sends your package to the Piwik.org server.

## Resources

### dupload configuration

Your basic dupload configuration should look like this:

	package config;
	$preupload{'changes'} = '/usr/share/dupload/gpg-check %1';
	$preupload{'deb'} = 'lintian --color auto -v -i %1';

	$cfg{'piwik'} = {
		fqdn => "piwik.org",
		method => "scpb",
		mailto => 'aurelien@requiem.fr',
		cc => 'matt@piwik.org',
		login => 'piwik-package',
		incoming => '/home/piwik-package/incoming/stable/',
		dinstall_runs => 0,
	};

	1;

### Release process

The ``make release`` command does multiple things for you in the background

  * Check your environment
  * Check the latest Piwik version
  * Download the changelog and Update ``debian/changelog`` if needed
  * Download, unpack and clean the Piwik directory
  * Generate the Debian package
  * Digitally sign the Debian package
  * Call ``lintian`` to ensure your package complies with the Debian standards

### Versions

Understanding the different Piwik versions

  * Official Web releases
    * ``2.0`` is a major Piwik release as found on [Piwik.org](http://piwik.org)
    * ``2.0.1`` is a minor Piwik release as found on [Piwik.org](http://piwik.org)
  * Official Debian releases
    * ``2.0-1`` or ``2.0.1-1`` are the first Debian package releases of a major or minor version of Piwik
    * ``2.0-2`` or ``2.0.1-2`` are intermediate Debian package releases containing only packaging changes


### Details about ``debian/changelog``

The file ``debian/changelog`` contains 2 sorts of entries

  1. For all major and minor releases (``*-1``)

     The changelog details as found on the Piwik.org website. This includes the bug numbers.

  2. For all intermediate versions (``*-2``, ``*-3``, ...)

     These changelog entries describe the internal package changes, but no core code changes. (ie. permission fixes, cleanup, ...)

# Background history

I needed to install Piwik on a Debian server for a client. I found Fabrizio's work but sadly this didn't work with the latest Piwik (1.12) version. So, as I maintain my own internal package repository, I decided to adapt his work and create a true vanilla version of Piwik for Debian. I also tried my best to ensure a good security level (files owned by ``root``, configs in ``/etc/piwik`` and generated files in ``/var/lib/piwik/``).

Some Debian purist may scream at me for all the lintian rules, licenses files and other problems. The idea is not to submit my work to the Debian project, but at least offer an interim for people willing to maintain their Piwik installation via a proper package.

# Credits

  * Aur&eacute;lien Requiem (aurelien AT requiem DOT fr) for packaging Piwik, automatic some of the tasks and the related documentation
  * Matthieu Aubry (matt AT piwik DOT org) for his advices, additional checks and fixes
  * Main credit goes to the Piwik team for their fantastic work
  * All people contributing to the Piwik project and the funders
  * Fabrizio Regalli and the Debian team for some of the files reused and adapted (see ``debian/copyright``)

