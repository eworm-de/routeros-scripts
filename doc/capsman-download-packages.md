Download packages for CAP upgrade from CAPsMAN
=============================================

[◀ Go back to main README](../README.md)

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

Optionally install [global-wait](global-wait.md) and add a scheduler to run
after startup:

    $ScriptInstallUpdate global-wait;
    / system scheduler add name=capsman-download-packages on-event="/ system script { run global-wait; run capsman-download-packages; }" start-time=startup;

Only packages available in older version are downloaded. For initial setup
place the required packages to CAPsMAN package path (see
`/ caps-man manager`). The packages can be downloaded from device with
function `$DownloadPackage`, use something like this to download latest
packages to directory `routeros`:

    $DownloadPackage system "" arm routeros;
    $DownloadPackage security "" arm routeros;
    [...]
    $DownloadPackage system "" mipsbe routeros;
    $DownloadPackage security "" mipsbe routeros;
    [...]

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
* [Wait for configuration und functions](global-wait.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
