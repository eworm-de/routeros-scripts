Upload backup to Mikrotik cloud
===============================

[◀ Go back to main README](../README.md)

🛈 This script can not be used on its own but requires the base installation.
See [main README](../README.md) for details.

Description
-----------

This script uploads [binary backup to Mikrotik cloud](https://wiki.mikrotik.com/wiki/Manual:IP/Cloud#Backup).

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate cloud-backup;

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `BackupPassword`: password to encrypt the backup with
* `BackupRandomDelay`: delay up to amount of seconds when run from scheduler

Also notification settings are required for e-mail and telegram.

Usage and invocation
--------------------

Just run the script:

    / system script run cloud-backup;

Creating a scheduler may be an option:

    / system scheduler add interval=1w name=cloud-backup on-event="/ system script run cloud-backup;" start-time=09:20:00;

See also
--------

* [Send backup via e-mail](email-backup.md)
* [Upload backup to server](upload-backup.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
