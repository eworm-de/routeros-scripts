Manage system update
====================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

In rare cases RouterOS fails to properly downlaod package on update
(`/ system package update install`), resulting in borked system with missing
packages. This script tries to avoid this situation by doing some basic
verification.

But it provides some extra functionality:

* send backup via e-mail if [backup-email](backup-email.md) is installed
* upload backup if [backup-upload](backup-upload.md) is installed
* schedule reboot at night

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate packages-update;

It is automatically run by [check-routeros-update](check-routeros-update.md)
if available.

Usage and invocation
--------------------

Alternatively run it manually:

    / system script run packages-update;

See also
--------

* [Notify on RouterOS update](check-routeros-update.md)
* [Upload backup to Mikrotik cloud](backup-cloud.md)
* [Send backup via e-mail](backup-email.md)
* [Upload backup to server](backup-upload.md)
* [Automatically upgrade firmware and reboot](firmware-upgrade-reboot.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
