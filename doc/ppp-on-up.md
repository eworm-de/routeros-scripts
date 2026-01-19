Run scripts on ppp connection
=============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.19-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is supposed to run on established ppp connection. Currently
it does:

* release IPv6 dhcp leases (and thus force a renew)
* run [update-tunnelbroker](update-tunnelbroker.md)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ppp-on-up;

... and make it the `on-up` script for ppp profile:

    /ppp/profile/set on-up=ppp-on-up [ find ];

See also
--------

* [Update configuration on IPv6 prefix change](ipv6-update.md)
* [Update tunnelbroker configuration](update-tunnelbroker.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
