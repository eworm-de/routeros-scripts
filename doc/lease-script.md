Run other scripts on DHCP lease
===============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.14-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is supposed to run from dhcp server as lease script. On a dhcp
lease it runs each script containing the following line, where `##` is a
decimal number for ordering:

    # provides: lease-script, order=##

Currently it runs if available, in order:

* [dhcp-to-dns](dhcp-to-dns.md)
* [collect-wireless-mac](collect-wireless-mac.md)
* [dhcp-lease-comment](dhcp-lease-comment.md)
* `hotspot-to-wpa-cleanup`, which is an optional cleanup script
  of [hotspot-to-wpa](hotspot-to-wpa.md)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate lease-script;

... and add it as `lease-script` to your dhcp server:

    /ip/dhcp-server/set lease-script=lease-script [ find ];

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)
* [Comment DHCP leases with info from access list](dhcp-lease-comment.md)
* [Create DNS records for DHCP leases](dhcp-to-dns.md)
* [Use WPA network with hotspot credentials](hotspot-to-wpa.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
