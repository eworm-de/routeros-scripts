Comment DHCP leases with info from access list
==============================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script adds comments to dynamic dhcp server leases. Infos are taken
from wireless access list.

Requirements and installation
-----------------------------

Depending on whether you use `wifi` package (`/interface/wifi`), legacy
wifi with CAPsMAN (`/caps-man`) or local wireless interface
(`/interface/wireless`) you need to install a different script.

For `wifi`:

    $ScriptInstallUpdate dhcp-lease-comment.wifi;

For legacy CAPsMAN:

    $ScriptInstallUpdate dhcp-lease-comment.capsman;

For legacy local interface:

    $ScriptInstallUpdate dhcp-lease-comment.local;

Configuration
-------------

Infos are taken from wireless access list. Add entries with proper comments
there. You may want to use [collect-wireless-mac](collect-wireless-mac.md)
to prepare entries.

Usage and invocation
--------------------

Run this script from a dhcp server as lease-script to update the comment
just after a new address is leased. You may want to use
[lease-script](lease-script.md).

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)
* [Create DNS records for DHCP leases](dhcp-to-dns.md)
* [Run other scripts on DHCP lease](lease-script.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
