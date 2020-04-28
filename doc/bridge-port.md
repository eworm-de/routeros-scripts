Manage ports in bridge
======================

[◀ Go back to main README](../README.md)

Description
-----------

These scripts are supposed to handle interfaces and switching them from
one bridge to another.

Requirements and installation
-----------------------------

Just install the scripts:

    $ScriptInstallUpdate bridge-port-to-default,bridge-port-toggle;

Configuration
-------------

The configuration goes to ports' comments (`/ interface bridge port`).

    / interface bridge port add bridge=br-guest comment="default=dhcp-client, alt=br-guest" disabled=yes interface=en1;
    / interface bridge port add bridge=br-intern comment="default=br-intern, alt=br-guest" interface=en2;
    / interface bridge port add bridge=br-guest comment="default=br-guest, extra=br-extra" interface=en3;

Also dhcp client can be handled:

    / ip dhcp-client add comment="toggle with bridge port" disabled=no interface=en1;

There is also global configuration:

* `BridgePortTo`: specify the configuration to be applied by default

Install [global-wait](global-wait.md) and add a scheduler to start with
default setup on system startup:

    $ScriptInstallUpdate global-wait;
    / system scheduler add name=bridge-port-to-default on-event="/ system script { run global-wait; run bridge-port-to-default; }" start-time=startup;

Usage and invocation
--------------------

The usage examples show what happens with the configuration from above.

Running the script `bridge-port-to-default` applies all configuration given
with `default=`:

    / system script run bridge-port-to-default;

For the three interfaces we get this configuration:

* The special value `dhcp-client` enables the dhcp client for interface `en1`. The bridge port entry is disabled.
* Interface `en2` is put in bridge `br-intern`.
* Interface `en3` is put in bridge `br-guest`.

Running the script `bridge-port-toggle` toggles to configuration given
with `alt=`:

    / system script run bridge-port-toggle;

* Interface `en1` is put in bridge `br-guest`, dhcp client for the interface is disabled.
* Interface `en2` is put in bridge `br-guest`.
* Interface `en3` is unchanged, stays in bridge `br-guest`.

Running the script `bridge-port-toggle` again toggles back to configuration
given with `default=`.

More configuration can be loaded by setting `BridgePortTo`:

    :set BridgePortTo "extra";
    / system script run bridge-port-to-default;

* Interfaces `en1` and `en2` are unchanged.
* Interface `en3` is put in bridge `br-intern`.

See also
--------

* [Wait for configuration und functions](global-wait.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
