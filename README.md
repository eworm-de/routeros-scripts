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

Specific scripts may require even newer RouterOS version, for example cloud
backup was added in 6.44.

Initial setup
-------------

### Get me ready!

If you know how things work just copy and paste the
[initial commands](initial-commands). Remember to edit and rerun
`global-config-overlay`!
First time useres should take the long way below.

### Live presentation

Want to see it in action? I've had a presentation [Repository based
RouterOS script distribution](https://www.youtube.com/watch?v=B9neG3oAhcY)
including demonstation recorded live at [MUM Europe
2019](https://mum.mikrotik.com/2019/EU/) in Vienna.

### The long way in detail

The update script does server certificate verification, so first step is to
download the certificates. If you intend to download the scripts from a
different location (for example from github.com) install the corresponding
certificate chain.

    [admin@MikroTik] > / tool fetch "https://git.eworm.de/cgit/routeros-scripts/plain/certs/Let%27s%20Encrypt%20Authority%20X3.pem" dst-path="letsencrypt.pem"
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
         certificates-imported: 3
         private-keys-imported: 0
                files-imported: 1
           decryption-failures: 0
      keys-with-no-certificate: 0

For basic verification we rename the certifiactes and print their count. Make
sure the certificate count is **three**.

    [admin@MikroTik] > / certificate set name="ISRG-Root-X1" [ find where fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" ]
    [admin@MikroTik] > / certificate set name="Let-s-Encrypt-Authority-X3" [ find where fingerprint="731d3d9cfaa061487a1d71445a42f67df0afca2a6c2d2f98ff7b3ce112b1f568" ]
    [admin@MikroTik] > / certificate set name="DST-Root-CA-X3" [ find where fingerprint="0687260331a72403d909f105e69bcf0d32e1bd2493ffc6d9206d11bcd6770739" ]
    [admin@MikroTik] > / certificate print count-only where fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" or fingerprint="731d3d9cfaa061487a1d71445a42f67df0afca2a6c2d2f98ff7b3ce112b1f568" or fingerprint="0687260331a72403d909f105e69bcf0d32e1bd2493ffc6d9206d11bcd6770739"
    3

Always make sure there are no certificates installed you do not know or want!

Actually we do not require the certificate named `DST Root CA X3`, but as it
is used by `Let's Encrypt` to cross-sign we install it anyway - this makes
sure things do not go wrong if the intermediate certificate is replaced.
The IdenTrust certificate *should* be available from their
[download page](https://www.identrust.com/support/downloads). The site is
crap and a good example how to *not* do it.

Now let's download the main scripts and add them in configuration on the fly.

    [admin@MikroTik] > :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions"; "script-updates" } do={ / system script add name=$Script source=([ / tool fetch check-certificate=yes-without-crl ("https://git.eworm.de/cgit/routeros-scripts/plain/" . $Script) output=user as-value]->"data"); }

The configuration needs to be tweaked for your needs. Make sure not to send
your mails to `mail@example.com`! Edit `global-config-overlay`, copy
configuration from `global-config`.

    [admin@MikroTik] > / system script edit global-config-overlay source

And finally load configuration and functions and add the scheduler.

    [admin@MikroTik] > / system script { run global-config; run global-config-overlay; run global-functions; }
    [admin@MikroTik] > / system scheduler add name="global-scripts" start-time=startup on-event="/ system script { run global-config; run global-config-overlay; run global-functions; }"

Updating scripts
----------------

To update existing scripts just run `script-updates`.

    [admin@MikroTik] > / system script run script-updates

Adding a script
---------------

To add a script from the repository create a configuration item first, then
update scripts to fetch the source.

    [admin@MikroTik] > / system script add name="check-routeros-update"
    [admin@MikroTik] > / system script run script-updates

Scheduler and events
--------------------

Most scripts are designed to run regularly from
[scheduler](https://wiki.mikrotik.com/wiki/Manual:System/Scheduler). We just
added `check-routeros-update`, so let's run it every hour to make sure not to
miss an update.

    [admin@MikroTik] > / system scheduler add name="check-routeros-update" interval=1h on-event="/ system script run check-routeros-update;"

Some events can run a script. If you want your DHCP hostnames to be available
in DNS use `dhcp-to-dns` with the events from dhcp server. For a regular
cleanup add a scheduler entry.

    [admin@MikroTik] > / system script add name="dhcp-to-dns"
    [admin@MikroTik] > / system script run script-updates
    [admin@MikroTik] > / ip dhcp-server set lease-script=dhcp-to-dns [ find ]
    [admin@MikroTik] > / system scheduler add name="dhcp-to-dns" interval=5m on-event="/ system script run dhcp-to-dns;"

There's much more to explore... Have fun!

## Contribute

Thanks a lot for [past contributions](CONTRIBUTIONS.md)!

### Patches, issues and whishlist

Feel free to contact me via e-mail or open an
[issue at github](https://github.com/eworm-de/routeros-scripts/issues).

### Donate

This project is developed in private spare time and usage is free of charge
for you. If you like the scripts and think this is of value for you or your
business please consider to
[donate with PayPal](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J).

[![donate with PayPal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

Thanks a lot for your support!

## Upstream

URL:
[GitHub.com](https://github.com/eworm-de/routeros-scripts#routeros-scripts)

Mirror:
[eworm.de](https://git.eworm.de/cgit/routeros-scripts/about/)
[GitLab.com](https://gitlab.com/eworm-de/routeros-scripts#routeros-scripts)

---
[▲ Go back to top](#top)
