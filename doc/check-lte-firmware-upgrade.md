Notify on LTE firmware upgrade
==============================

[◀ Go back to main README](../README.md)

Description
-----------

This script is run from scheduler periodically, checking for LTE firmware
upgrades. Currently supported LTE hardware:

* R11e-LTE
* R11e-LTE-US
* R11e-4G
* R11e-LTE6

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate check-lte-firmware-upgrade;

... and create a scheduler:

    / system scheduler add interval=1d name=check-lte-firmware-upgrade on-event="/ system script run check-lte-firmware-upgrade;" start-time=startup;

Configuration
-------------

Notification setting are required for e-mail and telegram.

See also
--------

* [Notify on RouterOS update](check-routeros-update.md)
* [Install LTE firmware upgrade](unattended-lte-firmware-upgrade.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
