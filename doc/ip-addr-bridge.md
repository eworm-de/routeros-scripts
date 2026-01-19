Manage IP addresses with bridge status
======================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.19-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

Description
-----------

With RouterOS an IP address is always active, even if an interface is down.
Other venders handle this differently - and sometimes this behavior is
expected. This script mimics this behavior.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ip-addr-bridge;

... and make it run from scheduler:

    /system/scheduler/add name=ip-addr-bridge on-event="/system/script/run ip-addr-bridge;" start-time=startup;

This will disable IP addresses on bridges without at least one running port.
The IP address is enabled if at least one port is running.

Note that IP addresses on bridges without a single port (acting as loopback
interface) are ignored.

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
