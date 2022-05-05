RouterOS Scripts
================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?style=social)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?style=social)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?style=social)](https://github.com/eworm-de/routeros-scripts/watchers)

![RouterOS Scripts Logo](logo.svg)

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

> ⚠️ **Warning**: Some details changed. So see the presentation, then follow
> the steps below for up-to-date commands.

### The long way in detail

The update script does server certificate verification, so first step is to
download the certificates. If you intend to download the scripts from a
different location (for example from github.com) install the corresponding
certificate chain.

    / tool fetch "https://git.eworm.de/cgit/routeros-scripts/plain/certs/R3.pem" dst-path="letsencrypt-R3.pem";

![screenshot: download certs](README.d/01-download-certs.avif)

Note that the commands above do *not* verify server certificate, so if you
want to be safe download with your workstations's browser and transfer the
files to your MikroTik device.

* [ISRG Root X1](https://letsencrypt.org/certs/isrgrootx1.pem)
* Let's Encrypt [R3](https://letsencrypt.org/certs/lets-encrypt-r3.pem)

Then we import the certificates.

    / certificate import file-name=letsencrypt-R3.pem passphrase="";

![screenshot: import certs](README.d/02-import-certs.avif)

For basic verification we rename the certificates and print their count. Make
sure the certificate count is **two**.

    / certificate set name="R3" [ find where fingerprint="67add1166b020ae61b8f5fc96813c04c2aa589960796865572a3c7e737613dfd" ];
    / certificate set name="ISRG-Root-X1" [ find where fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" ];
    / certificate print count-only where fingerprint="67add1166b020ae61b8f5fc96813c04c2aa589960796865572a3c7e737613dfd" or fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6";

![screenshot: check certs](README.d/03-check-certs.avif)

Always make sure there are no certificates installed you do not know or want!

All following commands will verify the server certificate. For validity the
certificate's lifetime is checked with local time, so make sure the device's
date and time is set correctly!

One extra step is required if you run RouterOS v6:

    :global ScriptUpdatesUrlSuffix "\?h=routeros-v6";

Now let's download the main scripts and add them in configuration on the fly.

    :global ScriptUpdatesUrlSuffix;
    :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={ / system script add name=$Script source=([ / tool fetch check-certificate=yes-without-crl ("https://git.eworm.de/cgit/routeros-scripts/plain/" . $Script . $ScriptUpdatesUrlSuffix) output=user as-value]->"data"); };

![screenshot: import scripts](README.d/04-import-scripts.avif)

The configuration needs to be tweaked for your needs. Edit
`global-config-overlay`, copy configuration from
[`global-config`](global-config) (the one without `-overlay`).
Save changes and exit with `Ctrl-o`.

    / system script edit global-config-overlay source;

![screenshot: edit global-config-overlay](README.d/05-edit-global-config-overlay.avif)

And finally load configuration and functions and add the scheduler.

    / system script { run global-config; run global-functions; };
    / system scheduler add name="global-scripts" start-time=startup on-event="/ system script { run global-config; run global-functions; }";

![screenshot: run and schedule scripts](README.d/06-run-and-schedule-scripts.avif)

The last step is optional: Add this scheduler **only** if you want the scripts
to be updated automatically!

    / system scheduler add name="ScriptInstallUpdate" start-time=startup interval=1d on-event=":global ScriptInstallUpdate; \$ScriptInstallUpdate;";

![screenshot: schedule update](README.d/07-schedule-update.avif)

### Changes for RouterOS v6

RouterOS v7 is the way to go, let's consider RouterOS v6 deprecated.
If you want to stay with RouterOS v6 for some time add these lines
to your `global-config-overlay`, if missing:

    # Use branch routeros-v6 with RouterOS v6:
    :global ScriptUpdatesUrlSuffix "\?h=routeros-v6";

Then reload the configuration.

Updating scripts
----------------

To update existing scripts just run function `$ScriptInstallUpdate`. If
everything is up-to-date it will not produce any output.

    $ScriptInstallUpdate;

![screenshot: update scripts](README.d/08-update-scripts.avif)

Adding a script
---------------

To add a script from the repository run function `$ScriptInstallUpdate` with
a comma separated list of script names.

    $ScriptInstallUpdate check-certificates,check-routeros-update;

![screenshot: install scripts](README.d/09-install-scripts.avif)

Scheduler and events
--------------------

Most scripts are designed to run regularly from
[scheduler](https://wiki.mikrotik.com/wiki/Manual:System/Scheduler). We just
added `check-routeros-update`, so let's run it every hour to make sure not to
miss an update.

    / system scheduler add name="check-routeros-update" interval=1h on-event="/ system script run check-routeros-update;";

![screenshot: schedule script](README.d/10-schedule-script.avif)

Some events can run a script. If you want your DHCP hostnames to be available
in DNS use `dhcp-to-dns` with the events from dhcp server. For a regular
cleanup add a scheduler entry.

    $ScriptInstallUpdate dhcp-to-dns,lease-script;
    / ip dhcp-server set lease-script=lease-script [ find ];
    / system scheduler add name="dhcp-to-dns" interval=5m on-event="/ system script run dhcp-to-dns;";

![screenshot: setup lease script](README.d/11-setup-lease-script.avif)

There's much more to explore... Have fun!

Available scripts
-----------------

* [Find and remove access list duplicates](doc/accesslist-duplicates.md)
* [Upload backup to Mikrotik cloud](doc/backup-cloud.md)
* [Send backup via e-mail](doc/backup-email.md)
* [Save configuration to fallback partition](doc/backup-partition.md)
* [Upload backup to server](doc/backup-upload.md)
* [Download packages for CAP upgrade from CAPsMAN](doc/capsman-download-packages.md)
* [Run rolling CAP upgrades from CAPsMAN](doc/capsman-rolling-upgrade.md)
* [Renew locally issued certificates](doc/certificate-renew-issued.md)
* [Renew certificates and notify on expiration](doc/check-certificates.md)
* [Notify about health state](doc/check-health.md)
* [Notify on LTE firmware upgrade](doc/check-lte-firmware-upgrade.md)
* [Notify on RouterOS update](doc/check-routeros-update.md)
* [Collect MAC addresses in wireless access list](doc/collect-wireless-mac.md)
* [Use wireless network with daily psk](doc/daily-psk.md)
* [Comment DHCP leases with info from access list](doc/dhcp-lease-comment.md)
* [Create DNS records for DHCP leases](doc/dhcp-to-dns.md)
* [Automatically upgrade firmware and reboot](doc/firmware-upgrade-reboot.md)
* [Wait for global functions und modules](doc/global-wait.md)
* [Send GPS position to server](doc/gps-track.md)
* [Use WPA2 network with hotspot credentials](doc/hotspot-to-wpa.md)
* [Create DNS records for IPSec peers](doc/ipsec-to-dns.md)
* [Update configuration on IPv6 prefix change](doc/ipv6-update.md)
* [Manage IP addresses with bridge status](doc/ip-addr-bridge.md)
* [Run other scripts on DHCP lease](doc/lease-script.md)
* [Manage LEDs dark mode](doc/leds-mode.md)
* [Forward log messages via notification](doc/log-forward.md)
* [Mode button with multiple presses](doc/mode-button.md)
* [Manage DNS and DoH servers from netwatch](doc/netwatch-dns.md)
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

[comment]: # (TODO: currently undocumented)
[comment]: # (* learn-mac-based-vlan)
[comment]: # (* manage-umts)

Available modules
-----------------

* [Manage ports in bridge](doc/mod/bridge-port-to.md)
* [Manage VLANs on bridge ports](doc/mod/bridge-port-vlan.md)
* [Inspect variables](doc/mod/inspectvar.md)
* [IP address calculation](doc/mod/ipcalc.md)
* [Send notifications via Matrix](doc/mod/notification-matrix.md)
* [Send notifications via Telegram](doc/mod/notification-telegram.md)
* [Download script and run it once](doc/mod/scriptrunonce.md)

Installing custom scripts & modules
-----------------------------------

My scripts cover a lot of use cases, but you may have your own ones. You can
still use my scripts to manage and deploy yours, by specifying `base-url`
(and `url-suffix`) for each script.

This will fetch and install a script `hello-world.rsc` from the given url:

    $ScriptInstallUpdate hello-world.rsc "base-url=https://git.eworm.de/cgit/routeros-scripts/plain/README.d/"

![screenshot: install custom script](README.d/12-install-custom-script.avif)

(Yes, the example url still belongs to the repository for easy
handling - but the url can be what ever you use.)

For a script to be considered valid it has to begin with a *magic taken*.
Have a look at [any script](README.d/hello-world.rsc) and copy the first line.

Starting a script's name with `mod/` makes it a module and it is run
automatically by `global-functions`.

Contact
-------

We have a Telegram Group [RouterOS-Scripts](https://t.me/routeros_scripts)!

![RouterOS Scripts Telegram Group](README.d/telegram-group.avif)

Get help, give feedback or just chat - but do not expect free professional
support!

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
