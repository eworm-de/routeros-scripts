Manage ports in bridge
======================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.12-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

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

The configuration goes to ports' comments (`/interface/bridge/port`).

    /interface/bridge/port/add bridge=br-guest comment="default=dhcp-client, alt=br-guest" disabled=yes interface=en1;
    /interface/bridge/port/add bridge=br-intern comment="default=br-intern, alt=br-guest" interface=en2;
    /interface/bridge/port/add bridge=br-guest comment="default=br-guest, extra=br-extra" interface=en3;

Also dhcp client can be handled:

    /ip/dhcp-client/add comment="toggle with bridge port" disabled=no interface=en1;

Add a scheduler to start with default setup on system startup:

    $ScriptInstallUpdate global-wait;
    /system/scheduler/add name=bridge-port-to on-event="/system/script/run global-wait; :global BridgePortTo; \$BridgePortTo default;" start-time=startup;

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

* [Wait for global functions und modules](../global-wait.md)
* [Manage VLANs on bridge ports](bridge-port-vlan.md)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
