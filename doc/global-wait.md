Wait for global functions and modules
=====================================

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

The global functions from `global-functions` and modules are loaded by
scheduler at system startup. Running these functions at system startup may
result in race condition where configuration and/or function are not yet
available. This script is supposed to wait for everything being prepared.

Do **not** add this script `global-wait` to the `global-scripts` scheduler!
It would inhibit the initialization of configuration and functions.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate global-wait;

... and add it to your scheduler, for example in combination with the module
to [manage VLANs on bridge ports](mod/bridge-port-vlan.md):

    /system/scheduler/add name=bridge-port-vlan on-event="/system/script/run global-wait; :global BridgePortVlan; \$BridgePortVlan default;" start-time=startup;

See also
--------

* [Manage ports in bridge](mod/bridge-port-to.md)
* [Manage VLANs on bridge ports](mod/bridge-port-vlan.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
