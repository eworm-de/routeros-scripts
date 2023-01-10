Save configuration to fallback partition
========================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script saves the current configuration to fallback
[partition](https://wiki.mikrotik.com/wiki/Manual:Partitions).

For this to work you need a device with sufficient flash storage that is
properly partitioned.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate backup-partition;

Usage and invocation
--------------------

Just run the script:

    /system/script/run backup-partition;

Creating a scheduler may be an option:

    /system/scheduler/add interval=1w name=backup-partition on-event="/system/script/run backup-partition;" start-time=09:30:00;

See also
--------

* [Upload backup to Mikrotik cloud](backup-cloud.md)
* [Send backup via e-mail](backup-email.md)
* [Upload backup to server](backup-upload.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
