Save configuration to fallback partition
========================================

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

This script saves the current configuration to fallback
[partition](https://wiki.mikrotik.com/wiki/Manual:Partitions).
It can also copy-over the RouterOS installation when run interactively
or just before a feature update.

For this to work you need a device with sufficient flash storage that is
properly partitioned.

To make you aware of a possible issue a scheduler logging a warning is
added in the backup partition's configuration. You may want to use
[log-forward](log-forward.md) to be notified.

> ⚠️ **Warning**: By default only the configuration is saved to backup
> partition. Every now and then you should copy your installation over
> for a recent RouterOS version! See below for options.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate backup-partition;

Configuration
-------------

The configuration goes to `global-config-overlay`, the only parameter is:

* `BackupPartitionCopyBeforeFeatureUpdate`: copy-over the RouterOS
  installation when a feature update is pending

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Usage and invocation
--------------------

Just run the script:

    /system/script/run backup-partition;

When run interactively from terminal it supports to copy-over the RouterOS
installation when versions differ.

Creating a scheduler may be an option:

    /system/scheduler/add interval=1w name=backup-partition on-event="/system/script/run backup-partition;" start-time=09:30:00;

See also
--------

* [Upload backup to Mikrotik cloud](backup-cloud.md)
* [Send backup via e-mail](backup-email.md)
* [Upload backup to server](backup-upload.md)
* [Forward log messages via notification](log-forward.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
