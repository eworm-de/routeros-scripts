Manage system update
====================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.19-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

In rare cases RouterOS fails to properly downlaod package on update
(`/system/package/update/install`), resulting in borked system with missing
packages. This script tries to avoid this situation by doing some basic
verification.

But it provides some extra functionality:

* upload backup to Mikrotik cloud if [backup-cloud](backup-cloud.md) is
  installed
* send backup via e-mail if [backup-email](backup-email.md) is installed
* save configuration to fallback partition if
  [backup-partition](backup-partition.md) is installed
* upload backup to server if [backup-upload](backup-upload.md) is installed
* schedule reboot at night

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate packages-update;

It is automatically run by [check-routeros-update](check-routeros-update.md)
if available.

Configuration
-------------

The configuration goes to `global-config-overlay`, this is the only parameter:

* `PackagesUpdateDeferReboot`: defer the reboot for night (between 3 AM and
  5 AM), use a numerical value in days suffixed with a `d` to defer further

By modifying the scheduler's `start-time` you can force the reboot at
different time.

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Usage and invocation
--------------------

Alternatively run it manually:

    /system/script/run packages-update;

See also
--------

* [Upload backup to Mikrotik cloud](backup-cloud.md)
* [Send backup via e-mail](backup-email.md)
* [Save configuration to fallback partition](backup-partition.md)
* [Upload backup to server](backup-upload.md)
* [Notify on RouterOS update](check-routeros-update.md)
* [Automatically upgrade firmware and reboot](firmware-upgrade-reboot.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
