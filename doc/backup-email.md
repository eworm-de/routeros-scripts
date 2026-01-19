Send backup via e-mail
======================

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

This script sends binary backup (`/system/backup/save`) and complete
configuration export (`/export terse show-sensitive`) via e-mail.

Requirements and installation
-----------------------------

Just install the script and the required module:

    $ScriptInstallUpdate mod/notification-email,backup-email;

Also make sure you configure
[sending notifications via e-mail](mod/notification-email.md).

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `BackupSendBinary`: whether to send binary backup
* `BackupSendExport`: whether to send configuration export
* `BackupSendGlobalConfig`: whether to send `global-config-overlay`
* `BackupPassword`: password to encrypt the backup with
* `BackupRandomDelay`: delay up to amount of seconds when run from scheduler

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Usage and invocation
--------------------

Just run the script:

    /system/script/run backup-email;

Creating a scheduler may be an option:

    /system/scheduler/add interval=1w name=backup-email on-event="/system/script/run backup-email;" start-time=09:15:00;

See also
--------

* [Upload backup to Mikrotik cloud](backup-cloud.md)
* [Save configuration to fallback partition](backup-partition.md)
* [Send notifications via e-mail](mod/notification-email.md)
* [Upload backup to server](backup-upload.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
