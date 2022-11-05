Notify on a new DHCP lease 
==========================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is run from scheduler periodically, checking for LTE state changes.

### Sample notification

![notify-on-dhcp-lease notification](notify-on-dhcp-lease.d/notification.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate notify-on-dhcp-lease;

Requires lease-script installed:

    $ScriptInstallUpdate lease-script;

Configuration
-------------

The configuration goes to `global-config-overlay`, there are no additional parameters.

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
