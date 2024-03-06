Notify on RouterOS update
=========================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.12-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

The primary use of this script is to notify about RouterOS updates.

Run from a terminal you can start the update process or schedule it.

Centrally managing update process of several devices is possibly by
specifying versions safe to be updated on a web server. Versions seen
in neighbor discovery can be specified to be safe as well.

Also installing patch updates (where just last digit is increased)
automatically is supported.

> ⚠️ **Warning**: Installing updates is important from a security point
> of view. At the same time it can be source of serve breakage. So test
> versions in lab and read
> [changelog](https://mikrotik.com/download/changelogs/) and
> [forum](https://forum.mikrotik.com/viewforum.php?f=21) before deploying
> to your production environment! Automatic updates should be handled
> with care!

### Sample notification

![check-routeros-update notification](check-routeros-update.d/notification.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate check-routeros-update;

And add a scheduler for automatic update notification:

    /system/scheduler/add interval=1d name=check-routeros-update on-event="/system/script/run check-routeros-update;" start-time=startup;

Configuration
-------------

No extra configuration is required to receive notifications. Several
mechanisms are availalbe to enable automatic installation of updates.
The configuration goes to `global-config-overlay`, these are the parameters:

* `SafeUpdateNeighbor`: install updates automatically if at least one other
  device is seen in neighbor list with new version
* `SafeUpdateNeighborIdentity`: regular expression to match identity for
  trusted devices, leave empty to match all
* `SafeUpdatePatch`: install patch updates (where just last digit changes)
  automatically
* `SafeUpdateUrl`: url on webserver to check for safe update, the channel
  (`long-term`, `stable` or `testing`) is appended
* `SafeUpdateAll`: install **all** updates automatically

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

Usage and invocation
--------------------

Be notified when run from scheduler or run it manually:

    /system/script/run check-routeros-update;

If an update is found you can install it right away.

Installing script [packages-update](packages-update.md) gives extra options.

Tips & Tricks
-------------

The script checks for full connectivity before acting, so scheduling at
startup is perfectly valid:

    /system/scheduler/add name=check-routeros-update@startup on-event="/system/script/run check-routeros-update;" start-time=startup;

See also
--------

* [Automatically upgrade firmware and reboot](firmware-upgrade-reboot.md)
* [Manage system update](packages-update.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
