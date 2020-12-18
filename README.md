RouterOS Scripts
================

[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?style=social)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?style=social)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?style=social)](https://github.com/eworm-de/routeros-scripts/watchers)

[RouterOS](https://mikrotik.com/software) is the operating system developed
by [MikroTik](https://mikrotik.com/aboutus) for networking tasks. This
repository holds a number of [scripts](https://wiki.mikrotik.com/wiki/Manual:Scripting)
to manage RouterOS devices or extend their functionality.

*Use at your own risk*, pay attention to
[license and warranty](#license-and-warranty)!

Requirements
------------

Latest version of the scripts require recent RouterOS to function properly.
Make sure to install latest updates before you begin.

Specific scripts may require even newer RouterOS version.

Initial setup
-------------

### Get me ready!

If you know how things work just copy and paste the
[initial commands](INITIAL-COMMANDS.md). Remember to edit and rerun
`global-config-overlay`!
First time users should take the long way below.

### Live presentation

Want to see it in action? I've had a presentation [Repository based
RouterOS script distribution](https://www.youtube.com/watch?v=B9neG3oAhcY)
including demonstation recorded live at [MUM Europe
2019](https://mum.mikrotik.com/2019/EU/) in Vienna.

*Be warned!* Some details changed. So see the presentation, then follow
the steps below for up-to-date commands.

### The long way in detail

The update script does server certificate verification, so first step is to
download the certificates. If you intend to download the scripts from a
different location (for example from github.com) install the corresponding
certificate chain.

    [admin@MikroTik] > / tool fetch "https://git.eworm.de/cgit/routeros-scripts/plain/certs/R3.pem" dst-path="letsencrypt-R3.pem"
          status: finished
      downloaded: 4KiBC-z pause]
           total: 4KiB
        duration: 1s

Note that the commands above do *not* verify server certificate, so if you
want to be safe download with your workstations's browser and transfer the
files to your MikroTik device.

* [ISRG Root X1](https://letsencrypt.org/certs/isrgrootx1.pem)
* Let's Encrypt [R3](https://letsencrypt.org/certs/lets-encrypt-r3.pem)

Then we import the certificates.

    [admin@MikroTik] > / certificate import file-name=letsencrypt-R3.pem passphrase=""
         certificates-imported: 3
         private-keys-imported: 0
                files-imported: 1
           decryption-failures: 0
      keys-with-no-certificate: 0

For basic verification we rename the certifiactes and print their count. Make
sure the certificate count is **three**.

    [admin@MikroTik] > / certificate set name="R3" [ find where fingerprint="67add1166b020ae61b8f5fc96813c04c2aa589960796865572a3c7e737613dfd" ]
    [admin@MikroTik] > / certificate set name="ISRG-Root-X1" [ find where fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" ]
    [admin@MikroTik] > / certificate set name="DST-Root-CA-X3" [ find where fingerprint="0687260331a72403d909f105e69bcf0d32e1bd2493ffc6d9206d11bcd6770739" ]
    [admin@MikroTik] > / certificate print count-only where fingerprint="67add1166b020ae61b8f5fc96813c04c2aa589960796865572a3c7e737613dfd" or fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" or fingerprint="0687260331a72403d909f105e69bcf0d32e1bd2493ffc6d9206d11bcd6770739"
    3

Always make sure there are no certificates installed you do not know or want!

Actually we do not require the certificate named `DST Root CA X3`, but as it
is used by `Let's Encrypt` to cross-sign we install it anyway - this makes
sure things do not go wrong if the intermediate certificate is replaced.
The IdenTrust certificate *should* be available from their
[download page](https://www.identrust.com/support/downloads). The site is
crap and a good example how to *not* do it.

Now let's download the main scripts and add them in configuration on the fly.

    [admin@MikroTik] > :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={ / system script add name=$Script source=([ / tool fetch check-certificate=yes-without-crl ("https://git.eworm.de/cgit/routeros-scripts/plain/" . $Script) output=user as-value]->"data"); }

Mark `global-config-overlay` not to be overwritten by future updates.

    [admin@MikroTik] > / system script set comment="ignore" global-config-overlay

The configuration needs to be tweaked for your needs. Edit
`global-config-overlay`, copy configuration from
[`global-config`](global-config) (the one without `-overlay`).

    [admin@MikroTik] > / system script edit global-config-overlay source

And finally load configuration and functions and add the scheduler.

    [admin@MikroTik] > / system script { run global-config; run global-config-overlay; run global-functions; }
    [admin@MikroTik] > / system scheduler add name="global-scripts" start-time=startup on-event="/ system script { run global-config; run global-config-overlay; run global-functions; }"

The last step is optional: Add this scheduler **only** if you want the scripts
to be updated automatically!

    [admin@MikroTik] > / system scheduler add name="ScriptInstallUpdate" start-time=startup interval=1d on-event=":global ScriptInstallUpdate; \$ScriptInstallUpdate;"

Updating scripts
----------------

To update existing scripts just run function `$ScriptInstallUpdate`.

    [admin@MikroTik] > $ScriptInstallUpdate

Adding a script
---------------

To add a script from the repository run function `$ScriptInstallUpdate` with
a comma separated list of script names.

    [admin@MikroTik] > $ScriptInstallUpdate check-certificates,check-routeros-update

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

    [admin@MikroTik] > $ScriptInstallUpdate dhcp-to-dns,lease-script
    [admin@MikroTik] > / ip dhcp-server set lease-script=lease-script [ find ]
    [admin@MikroTik] > / system scheduler add name="dhcp-to-dns" interval=5m on-event="/ system script run dhcp-to-dns;"

There's much more to explore... Have fun!

Available Scripts
-----------------

* [Find and remove access list duplicates](doc/accesslist-duplicates.md)
* [Manage ports in bridge](doc/bridge-port.md)
* [Download packages for CAP upgrade from CAPsMAN](doc/capsman-download-packages.md)
* [Run rolling CAP upgrades from CAPsMAN](doc/capsman-rolling-upgrade.md)
* [Renew locally issued certificates](doc/certificate-renew-issued.md)
* [Renew certificates and notify on expiration](doc/check-certificates.md)
* [Notify about health state](doc/check-health.md)
* [Notify on LTE firmware upgrade](doc/check-lte-firmware-upgrade.md)
* [Notify on RouterOS update](doc/check-routeros-update.md)
* [Upload backup to Mikrotik cloud](doc/cloud-backup.md)
* [Collect MAC addresses in wireless access list](doc/collect-wireless-mac.md)
* [Use wireless network with daily psk](doc/daily-psk.md)
* [Comment DHCP leases with info from access list](doc/dhcp-lease-comment.md)
* [Create DNS records for DHCP leases](doc/dhcp-to-dns.md)
* [Send backup via e-mail](doc/email-backup.md)
* [Wait for configuration und functions](doc/global-wait.md)
* [Send GPS position to server](doc/gps-track.md)
* [Use WPA2 network with hotspot credentials](doc/hotspot-to-wpa.md)
* [Update configuration on IPv6 prefix change](doc/ipv6-update.md)
* [Manage IP addresses with bridge status](doc/ip-addr-bridge.md)
* [Run other scripts on DHCP lease](doc/lease-script.md)
* [Manage LEDs dark mode](doc/leds-mode.md)
* [Forward log messages via notification](doc/log-forward.md)
* [Mode button with multiple presses](doc/mode-button.md)
* [Notify on host up and down](doc/netwatch-notify.md)
* [Manage remote logging](doc/netwatch-syslog.md)
* [Visualize OSPF state via LEDs](doc/ospf-to-leds.md)
* [Manage system update](doc/packages-update.md)
* [Run scripts on ppp connection](doc/ppp-on-up.md)
* [Rotate NTP servers](doc/rotate-ntp.md)
* [Act on received SMS](doc/sms-action.md)
* [Forward received SMS](doc/sms-forward.md)
* [Import SSH keys](doc/ssh-keys-import.md)
* [Play Super Mario theme](doc/super-mario-theme.md)
* [Install LTE firmware upgrade](doc/unattended-lte-firmware-upgrade.md)
* [Update GRE configuration with dynamic addresses](doc/update-gre-address.md)
* [Update tunnelbroker configuration](doc/update-tunnelbroker.md)
* [Upload backup to server](doc/upload-backup.md)

[comment]: # (TODO: currently undocumented)
[comment]: # (* learn-mac-based-vlan)
[comment]: # (* manage-umts)

Contribute
----------

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

License and warranty
--------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
[GNU General Public License](COPYING.md) for more details.

Upstream
--------

URL:
[GitHub.com](https://github.com/eworm-de/routeros-scripts#routeros-scripts)

Mirror:
[eworm.de](https://git.eworm.de/cgit/routeros-scripts/about/)
[GitLab.com](https://gitlab.com/eworm-de/routeros-scripts#routeros-scripts)

---
[▲ Go back to top](#top)
