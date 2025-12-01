Install LTE firmware upgrade
============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

Description
-----------

This script upgrades LTE firmware on compatible devices:

* R11e-LTE
* R11e-LTE-US
* R11e-4G
* R11e-LTE6
* ... and more - probably what ever Mikrotik builds into their devices

A temporary scheduler is created to be independent from terminal. Thus
starting the upgrade process over the broadband connection is supported.

Requirements and installation
-----------------------------

The firmware is downloaded over the air, so a working broadband connection
on the lte interface to be updated is required! Having internet access from
different gateway is not sufficient!

Just install the script:

    $ScriptInstallUpdate unattended-lte-firmware-upgrade;

Usage and invocation
--------------------

Run the script if an upgrade for your LTE hardware is available:

    /system/script/run unattended-lte-firmware-upgrade;

Then be patient, go for a coffee and wait for the upgrade process to finish.

See also
--------

* [Notify on LTE firmware upgrade](check-lte-firmware-upgrade.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
