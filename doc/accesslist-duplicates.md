Find and remove access list duplicates
======================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is supposed to run interactively to find and remove duplicate
entries in wireless access list.

Requirements and installation
-----------------------------

Depending on whether you use `wifi` package (`/interface/wifi`), legacy
wifi with CAPsMAN (`/caps-man`) or local wireless interface
(`/interface/wireless`) you need to install a different script.

For `wifi`:

    $ScriptInstallUpdate accesslist-duplicates.wifi;

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
