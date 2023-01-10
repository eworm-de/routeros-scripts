Notify on LTE state update
==========================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is run from scheduler periodically, checking for LTE state changes.

### Sample notification

![check-lte-state-update notification](check-lte-state-update.d/notification.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate check-lte-state-update;

... and create a scheduler:

    /system/scheduler/add interval=1h name=check-lte-state-update on-event="/system/script/run check-lte-state-update;" start-time=startup;

Configuration
-------------

The configuration goes to `global-config-overlay`, this is the only parameter:

* `CheckLteStateUpdateBtestHost`: host to test for internet connectivity (btest server), leave empty to disable internet connectivity check
* `CheckLteStateUpdateBtestUser`: user to test for internet connectivity (btest server)
* `CheckLteStateUpdateBtestPassword`: password to test for internet connectivity (btest server)
* `CheckLteStateUpdateIP`: check the IP address, set to false to disable IP address check (default true, enabled)
* `CheckLteStateUpdatePrimaryBand`: check the primary band, set to true to enable primary band check, (default false, disabled)
* `CheckLteStateUpdateCABand`: check the CA band, set to true to enable CA band check, (default false, disabled)

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md) and/or
[telegram](mod/notification-telegram.md).

See also
--------

* [Notify on RouterOS update](check-routeros-update.md)
* [Install LTE firmware upgrade](unattended-lte-firmware-upgrade.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
