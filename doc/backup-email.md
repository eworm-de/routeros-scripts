Send backup via e-mail
======================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script sends binary backup (`/ system backup save`) and complete
configuration export (`/ export terse`) via e-mail.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate backup-email;

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `BackupSendBinary`: whether to send binary backup
* `BackupSendExport`: whether to send configuration export
* `BackupPassword`: password to encrypt the backup with
* `BackupRandomDelay`: delay up to amount of seconds when run from scheduler

Also valid e-mail settings are required to send mails.

Usage and invocation
--------------------

Just run the script:

    / system script run backup-email;

Creating a scheduler may be an option:

    / system scheduler add interval=1w name=backup-email on-event="/ system script run backup-email;" start-time=09:15:00;

See also
--------

* [Upload backup to Mikrotik cloud](backup-cloud.md)
* [Upload backup to server](backup-upload.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
