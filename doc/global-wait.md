Wait for global functions and modules
=====================================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

The global functions from `global-functions` and modules are loaded by
scheduler at system startup. Running these functions at system startup may
result in race condition where configuration and/or function are not yet
available. This script is supposed to wait for everything being prepared.

Do **not** add this script `global-wait` to the `global-scripts` scheduler!
It would inhibit the initialization of configuration and functions.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate global-wait;

... and add it to your scheduler, for example in combination with the module
to [manage VLANs on bridge ports](mod/bridge-port-vlan.md):

    /system/scheduler/add name=bridge-port-vlan on-event="/system/script/run global-wait; :global BridgePortVlan; \$BridgePortVlan default;" start-time=startup;

See also
--------

* [Manage ports in bridge](mod/bridge-port-to.md)
* [Manage VLANs on bridge ports](mod/bridge-port-vlan.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
