Manage ports in bridge
======================

[◀ Go back to main README](../README.md)

🛈 This module can not be used on its own but requires the base installation.
See [main README](../README.md) for details.

Description
-----------

This module and its functio are are supposed to handle interfaces and
switching them from one bridge to another.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/bridge-port-to;

Configuration
-------------

The configuration goes to ports' comments (`/ interface bridge port`).

    / interface bridge port add bridge=br-guest comment="default=dhcp-client, alt=br-guest" disabled=yes interface=en1;
    / interface bridge port add bridge=br-intern comment="default=br-intern, alt=br-guest" interface=en2;
    / interface bridge port add bridge=br-guest comment="default=br-guest, extra=br-extra" interface=en3;

Also dhcp client can be handled:

    / ip dhcp-client add comment="toggle with bridge port" disabled=no interface=en1;

Add a scheduler to start with default setup on system startup:

    / system scheduler add name=bridge-port-to on-event=":global GlobalFunctionsReady; :while (\$GlobalFunctionsReady != true) do={ :delay 500ms; }; :global BridgePortTo; \$BridgePortTo default;" start-time=startup;

Usage and invocation
--------------------

The usage examples show what happens with the configuration from above.

Running the function `$BridgePortTo` with parameter `default` applies all
configuration given with `default=`:

    $BridgePortTo default;

For the three interfaces we get this configuration:

* The special value `dhcp-client` enables the dhcp client for interface `en1`. The bridge port entry is disabled.
* Interface `en2` is put in bridge `br-intern`.
* Interface `en3` is put in bridge `br-guest`.

Running the function `$BridgePortTo` with parameter `alt` applies all
configuration given with `alt=`:

    $BridgePortTo alt;

* Interface `en1` is put in bridge `br-guest`, dhcp client for the interface is disabled.
* Interface `en2` is put in bridge `br-guest`.
* Interface `en3` is unchanged, stays in bridge `br-guest`.

Running the function `$BridgePortTo` with parameter `extra` applies another
configuration:

    $BridgePortTo extra;

* Interfaces `en1` and `en2` are unchanged.
* Interface `en3` is put in bridge `br-intern`.

See also
--------

* [Manage VLANs on bridge ports](bridge-port-vlan.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
