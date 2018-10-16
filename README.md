RouterOS Scripts
================

[RouterOS](https://mikrotik.com/software) is the operating system developed
by [MikroTik](https://mikrotik.com/aboutus) for networking tasks. This
repository holds a number of [scripts](https://wiki.mikrotik.com/wiki/Manual:Scripting)
to manage RouterOS devices or extend their functionality.

*Use at your own risk!*

Requirements
------------

Latest version of the scripts require at least **RouterOS 6.43** to function
properly. The changelog lists the corresponding change as follows:

> *) fetch - added "as-value" output format;

See branch `pre-6-43` if you want to use the scripts on devices with older
RouterOS version.

Initial setup
-------------

The update script does server certificate verification, so first step is to
download the certificates. If you intend to download the scripts from a
different location (for example from github.com) install the corresponding
certificate chain.

    [admin@MikroTik] > / tool fetch "https://git.eworm.de/cgit.cgi/routeros-scripts/plain/certs/731d3d9cfaa061487a1d71445a42f67df0afca2a6c2d2f98ff7b3ce112b1f568.pem" dst-path=letsencrypt.pem
          status: finished
      downloaded: 3KiBC-z pause]
           total: 3KiB
        duration: 1s

Note that the commands above do *not* verify server certificate, so if you
want to be safe download with your workstations's browser and transfer the
files to your MikroTik device.

* [ISRG Root X1](https://letsencrypt.org/certs/isrgrootx1.pem.txt)
* [Let's Encrypt Authority X3](https://letsencrypt.org/certs/letsencryptauthorityx3.pem.txt)

Then we import the certificates.

    [admin@MikroTik] > / certificate import file-name=letsencrypt.pem passphrase=""
         certificates-imported: 2
         private-keys-imported: 0
                files-imported: 1
           decryption-failures: 0
      keys-with-no-certificate: 0

For basic verification we rename and print the certifiactes. Make sure two
certificates are listed.

    [admin@MikroTik] > / certificate set name="ISRG-Root-X1" [ find where fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" ]
    [admin@MikroTik] > / certificate set name="Let-s-Encrypt-Authority-X3" [ find where fingerprint="731d3d9cfaa061487a1d71445a42f67df0afca2a6c2d2f98ff7b3ce112b1f568" ]
    [admin@MikroTik] > / certificate print terse where fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" or fingerprint="731d3d9cfaa061487a1d71445a42f67df0afca2a6c2d2f98ff7b3ce112b1f568"
     0        T name=ISRG-Root-X1 issuer=C=US,O=Internet Security Research Group,CN=ISRG Root X1 country=US organization=Internet Security Research Group common-name=ISRG Root X1 key-size=4096 days-valid=7305 trusted=yes key-usage=key-cert-sign,crl-sign serial-number=8210CFB0D240E3594463E0BB63828B00 fingerprint=96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6 invalid-before=jun/04/2015 13:04:38 invalid-after=jun/04/2035 13:04:38 expires-after=872w3d7m34s
     1   L    T name=Let-s-Encrypt-Authority-X3 issuer=C=US,O=Internet Security Research Group,CN=ISRG Root X1 country=US organization=Let's Encrypt common-name=Let's Encrypt Authority X3 key-size=2048 days-valid=1826 trusted=yes key-usage=digital-signature,key-cert-sign,crl-sign serial-number=D3B17226342332DCF40528512AEC9C6A fingerprint=731d3d9cfaa061487a1d71445a42f67df0afca2a6c2d2f98ff7b3ce112b1f568 invalid-before=oct/06/2016 17:43:55 invalid-after=oct/06/2021 17:43:55 expires-after=159w5d4h46m51s

Always make sure there are no certificates installed you do not know or want!

Now let's download the main scripts and add them in configuration on the fly.

    [admin@MikroTik] > :foreach script in={ "global-config"; "global-functions"; "script-updates" } do={ / system script add name=$script source=([ / tool fetch check-certificate=yes-without-crl ("https://git.eworm.de/cgit.cgi/routeros-scripts/plain/" . $script) output=user as-value]->"data"); }

The configuration needs to be tweaked for your needs. Make sure not to send
your mails to `mail@example.com`!

    [admin@MikroTik] > / system script edit global-config source

And finally load the configuration and add a scheduler.

    [admin@MikroTik] > / system script run global-config
    [admin@MikroTik] > / system scheduler add name=global-config start-time=startup on-event=global-config

Updating scripts
----------------

To update existing scripts just run `script-updates`.

    [admin@MikroTik] > / system script run script-updates

Adding a script
---------------

To add a script from the repository create a configuration item first, then
update scripts to fetch the source.

    [admin@MikroTik] > / system script add name=check-routeros-update
    [admin@MikroTik] > / system script run script-updates

Scheduler and events
--------------------

Most scripts are designed to run regularly from
[scheduler](https://wiki.mikrotik.com/wiki/Manual:System/Scheduler). We just
added `check-routeros-update`, so let's run it every hour to make sure not to
miss an update.

    [admin@MikroTik] > / system scheduler add name=check-routeros-update interval=1h on-event=check-routeros-update

Some events can run a script. If you want your DHCP hostnames to be available
in DNS use `dhcp-to-dns` with the events from dhcp server. For a regular
cleanup add a scheduler entry.

    [admin@MikroTik] > / system script add name=dhcp-to-dns
    [admin@MikroTik] > / system script run script-updates
    [admin@MikroTik] > / ip dhcp-server set lease-script=dhcp-to-dns [ find ]
    [admin@MikroTik] > / system scheduler add name=dhcp-to-dns interval=5m on-event=dhcp-to-dns

There's much more to explore... Have fun!

### Upstream

URL:
[GitHub.com](https://github.com/eworm-de/routeros-scripts#routeros-scripts)

Mirror:
[eworm.de](https://git.eworm.de/cgit.cgi/routeros-scripts/about/)
[GitLab.com](https://gitlab.com/eworm-de/routeros-scripts#routeros-scripts)

