Manage VLANs on bridge ports
============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.17-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module and its function are supposed to handle VLANs on bridge ports.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/bridge-port-vlan;

Configuration
-------------

Using named VLANs you have to add comments in bridge vlan menu:

    /interface/bridge/vlan/add bridge=bridge comment=intern tagged=br-local vlan-ids=10;
    /interface/bridge/vlan/add bridge=bridge comment=geust tagged=br-local vlan-ids=20;
    /interface/bridge/vlan/add bridge=bridge comment=extra tagged=br-local vlan-ids=30;

The configuration goes to ports' comments (`/interface/bridge/port`).

    /interface/bridge/port/add bridge=bridge comment="default=dhcp-client, alt=guest" disabled=yes interface=en1;
    /interface/bridge/port/add bridge=bridge comment="default=intern, alt=guest, extra=30" interface=en2;
    /interface/bridge/port/add bridge=bridge comment="default=guest, extra=extra" interface=en3;

Also dhcp client can be handled:

    /ip/dhcp-client/add comment="toggle with bridge port" disabled=no interface=en1;

Add a scheduler to start with default setup on system startup:

    $ScriptInstallUpdate global-wait;
    /system/scheduler/add name=bridge-port-vlan on-event="/system/script/run global-wait; :global BridgePortVlan; \$BridgePortVlan default;" start-time=startup;

Usage and invocation
--------------------

The usage examples show what happens with the configuration from above.

Running the function `$BridgePortVlan` with parameter `default` applies all
configuration given with `default=`:

    $BridgePortVlan default;

For the three interfaces we get this configuration:

* The special value `dhcp-client` enables the dhcp client for interface `en1`. The bridge port entry is disabled.
* Primary VLAN `intern` (ID `10`) is configured on `en2`.
* Primary VLAN `guest` (ID `20`) is configured on `en3`.

Running the function `$BridgePortVlan` with parameter `alt` applies all
configuration given with `alt=`:

    $BridgePortVlan alt;

* Primary VLAN `guest` (ID `20`) is configured on `en1`, dhcp client for the interface is disabled.
* Primary VLAN `guest` (ID `20`) is configured on `en2`.
* Interface `en3` is unchanged, primary VLAN `guest` (ID `20`) is unchanged.

Running the function `$BridgePortVlan` with parameter `extra` applies another
configuration:

* Interface `en1` is unchanged.
* Primary VLAN `extra` (via its ID `30`) is configured on `en2`.
* Primary VLAN `extra` (ID `30`) is configured on `en3`.

See also
--------

* [Wait for global functions und modules](../global-wait.md)
* [Manage ports in bridge](bridge-port-to.md)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
