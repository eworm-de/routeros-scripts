Automatically upgrade firmware and reboot
=========================================

[◀ Go back to main README](../README.md)

> 🛈 **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

RouterOS and firmware are upgraded separately, activating the latter
requires an extra reboot. This script handles upgrade and reboot.

> ⚠️ **Warning**: This *should* be bullet proof, but I can not guarantee. In
> worst case it has potential to cause a boot loop, so handle with care!

Requirements and installation
-----------------------------

Just install the script and create a scheduler:

    $ScriptInstallUpdate firmware-upgrade-reboot;
    / system scheduler add name=firmware-upgrade-reboot on-event="/ system script run firmware-upgrade-reboot;" start-time=startup;

Enjoy firmware being up to date and in sync with RouterOS.

See also
--------

* [Notify on RouterOS update](check-routeros-update.md)
* [Manage system update](packages-update.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
