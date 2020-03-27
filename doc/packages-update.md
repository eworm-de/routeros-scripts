Manage system update
====================

[◀ Go back to main README](../README.md)

Description
-----------

In rare cases RouterOS fails to properly downlaod package on update
(`/ system package update install`), resulting in borked system with missing
packages. This script tries to avoid this situation by doing some basic
verification.

But it provides some extra functionality:

* send backup via e-mail if [email-backup](email-backup.md) is installed
* upload backup if [upload-backup](upload-backup.md) is installed
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
* [Send backup via e-mail](email-backup.md)
* [Upload backup to server](upload-backup.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
