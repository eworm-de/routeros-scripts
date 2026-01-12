Create DNS records for IPSec peers
==================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.17-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script adds (and removes) dns records based on IPSec peers and their
dynamic addresses from mode-config.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ipsec-to-dns;

This script is run from scheduler:

    /system/scheduler/add interval=1m name=ipsec-to-dns on-event="/system/script/run ipsec-to-dns;" start-time=startup;

Configuration
-------------

On first run a disabled static dns record acting as marker (with comment
"`--- ipsec-to-dns above ---`") is added. Move this entry to define where new
entries are to be added.

The configuration goes to `global-config-overlay`, these are the parameters:

* `Domain`: the domain used for dns records
* `HostNameInZone`: whether or not to add the ipsec/dns server's hostname
* `PrefixInZone`: whether or not to add prefix `ipsec`

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

See also
--------

* [Create DNS records for DHCP leases](dns-to-dhcp.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
