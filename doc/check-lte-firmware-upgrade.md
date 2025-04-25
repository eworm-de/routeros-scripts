Notify on LTE firmware upgrade
==============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is run from scheduler periodically, checking for LTE firmware
upgrades. Currently supported LTE hardware:

* R11e-LTE
* R11e-LTE-US
* R11e-4G
* R11e-LTE6

### Sample notification

![check-lte-firmware-upgrade notification](check-lte-firmware-upgrade.d/notification.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate check-lte-firmware-upgrade;

... and create a scheduler:

    /system/scheduler/add interval=1d name=check-lte-firmware-upgrade on-event="/system/script/run check-lte-firmware-upgrade;" start-time=startup;

Configuration
-------------

Also notification settings are required for
[e-mail](mod/notification-email.md),
[gotify](mod/notification-gotify.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

See also
--------

* [Notify on RouterOS update](check-routeros-update.md)
* [Install LTE firmware upgrade](unattended-lte-firmware-upgrade.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
