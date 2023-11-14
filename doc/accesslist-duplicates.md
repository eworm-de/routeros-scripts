Find and remove access list duplicates
======================================

[⬅️ Go back to main README](../README.md)

[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.12-yellow?style=flat)](https://mikrotik.com/download/changelogs/)

> ℹ️️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is supposed to run interactively to find and remove duplicate
entries in wireless access list.

Requirements and installation
-----------------------------

Depending on whether you use `wifi` package (`/interface/wifi`), `wifiwave2`
package (`/interface/wifiwave2`), legacy wifi with CAPsMAN (`/caps-man`)
or local wireless interface (`/interface/wireless`) you need to install a
different script.

For `wifi` (RouterOS 7.13 and later):

    $ScriptInstallUpdate accesslist-duplicates.wifi;

For `wifiwave2` (up to RouterOS 7.12):

    $ScriptInstallUpdate accesslist-duplicates.wifiwave2;

For legacy CAPsMAN:

    $ScriptInstallUpdate accesslist-duplicates.capsman;

For legacy local interface:

    $ScriptInstallUpdate accesslist-duplicates.local;

Usage and invocation
--------------------

Run this script from a terminal:

    /system/script/run accesslist-duplicates.wifi;

![screenshot: example](accesslist-duplicates.d/01-example.avif)

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
