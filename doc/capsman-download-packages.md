Download packages for CAP upgrade from CAPsMAN
=============================================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

CAPsMAN can upgrate CAP devices. If CAPsMAN device and CAP device(s) are
differnet architecture you need to store packages for CAP device's
architecture on local storage.

This script automatically downloads these packages.

Requirements and installation
-----------------------------

Just install the script on CAPsMAN device:

    $ScriptInstallUpdate capsman-download-packages;

Optionally add a scheduler to run after startup:

    / system scheduler add name=capsman-download-packages on-event="/ system script run capsman-download-packages;" start-time=startup;

Packages available in local storage in older version are downloaded
unconditionally. The script tries to download missing packages by guessing
from system log.

Usage and invocation
--------------------

Run the script manually:

    / system script run capsman-download-packages;

... or from scheduler.

After package download all out-of-date CAP devices are upgraded automatically.
For a rolling upgrade install extra script
[capsman-rolling-upgrade](capsman-rolling-upgrade.md).

See also
--------

* [Run rolling CAP upgrades from CAPsMAN](capsman-rolling-upgrade.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
