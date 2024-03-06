Visualize OSPF state via LEDs
=============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.12-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

Physical interfaces have their state LEDs, software-defined connectivity
does not. This script helps to visualize whether or not an OSPF instance
is running.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ospf-to-leds;

... and add a scheduler to run the script periodically:

    /system/scheduler/add interval=20s name=ospf-to-leds on-event="/system/script/run ospf-to-leds;" start-time=startup;

Configuration
-------------

The configuration goes to OSPF instance's comment. To visualize state for
instance `default` via LED `user-led` set this:

    /routing/ospf/instance/set default comment="ospf-to-leds, leds=user-led";

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
