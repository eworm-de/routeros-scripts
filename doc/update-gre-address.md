Update GRE configuration with dynamic addresses
===============================================

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

Running a GRE tunnel over IPSec with IKEv2 is a common scenario. This is
easy to configure on client, but has an issue on server side: client IP
addresses are assigned dynamically via mode-config and have to be updated
for GRE interface.

This script handles the address updates and disables the interface if the
client is disconnected.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate update-gre-address;

... and add a scheduler to run the script periodically:

    /system/scheduler/add interval=30s name=update-gre-address on-event="/system/script/run update-gre-address;" start-time=startup;

Configuration
-------------

The configuration goes to interface's comment. Add the client's IKEv2
certificate CN into the comment:

    /interface/gre/set comment="ikev2-client1" gre-client1;

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
