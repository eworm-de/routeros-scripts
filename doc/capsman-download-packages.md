Download packages for CAP upgrade from CAPsMAN
=============================================

[⬅️ Go back to main README](../README.md)

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

Make sure you have the `package-path` set in your CAPsMAN configuration,
as that is where packages are downloaded to and where the system expects
them.

Then just install the script on CAPsMAN device.
Depending on whether you use `wifi` package (`/interface/wifi`) or legacy
wifi with CAPsMAN (`/caps-man`) you need to install a different script.

For `wifi`:

    $ScriptInstallUpdate capsman-download-packages.wifi;

For legacy CAPsMAN:

    $ScriptInstallUpdate capsman-download-packages.capsman;

Optionally add a scheduler to run after startup. For `wifi`:

    /system/scheduler/add name=capsman-download-packages on-event="/system/script/run capsman-download-packages.wifi;" start-time=startup;

For legacy CAPsMAN:

    /system/scheduler/add name=capsman-download-packages on-event="/system/script/run capsman-download-packages.capsman;" start-time=startup;

Packages available in local storage in older version are downloaded
unconditionally.

If no packages are found the script downloads a default set of packages:

 * `wifi`: `routeros` and `wifi-qcom` for *arm* and *arm64*, `wifi-qcom-ac` for *arm*
 * legacy CAPsMAN: `routeros` and `wireless` for *arm* and *mipsbe*

> ℹ️ **Info**: If you have packages in the directory and things go wrong for
> what ever unknown reason: Remove **all** packages and start over.

Usage and invocation
--------------------

Run the script manually:

    /system/script/run capsman-download-packages.wifi;

... or from scheduler.

After package download all out-of-date CAP devices are upgraded automatically.
For a rolling upgrade install extra script
[capsman-rolling-upgrade](capsman-rolling-upgrade.md).

See also
--------

* [Run rolling CAP upgrades from CAPsMAN](capsman-rolling-upgrade.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
