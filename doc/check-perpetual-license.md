Check perpetual license on CHR
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

On *Cloud Hosted Router* (*CHR*) the licensing is perpetual: Buy once, use
forever - but it needs regular renewal. This script checks licensing state
and sends a notification to warn before expiration.

### Sample notifications

![check-perpetual-license notification warn](check-perpetual-license.d/notification-01-warn.avif)  
![check-perpetual-license notification renew](check-perpetual-license.d/notification-02-renew.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate check-perpetual-license;

And add a scheduler for automatic update notification:

    /system/scheduler/add interval=1d name=check-perpetual-license on-event="/system/script/run check-perpetual-license;" start-time=startup;

Configuration
-------------

No extra configuration is required for this script, but notification
settings are required for
[e-mail](mod/notification-email.md),
[gotify](mod/notification-gotify.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

Usage and invocation
--------------------

Be notified when run from scheduler or run it manually:

    /system/script/run check-perpetual-license;

Tips & Tricks
-------------

The script checks for full connectivity before acting, so scheduling at
startup is perfectly valid:

    /system/scheduler/add name=check-perpetual-license@startup on-event="/system/script/run check-perpetual-license;" start-time=startup;

See also
--------

* [Notify on RouterOS update](check-routeros-update.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
