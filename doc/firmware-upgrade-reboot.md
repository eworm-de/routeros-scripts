Automatically upgrade firmware and reboot
=========================================

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

RouterOS and firmware are upgraded separately, activating the latter
requires an extra reboot. This script handles upgrade and reboot.

> ⚠️ **Warning**: This *should* be bullet proof, but I can not guarantee. In
> worst case it has potential to cause a boot loop, so handle with care!

Requirements and installation
-----------------------------

Just install the script and create a scheduler:

    $ScriptInstallUpdate firmware-upgrade-reboot;
    /system/scheduler/add name=firmware-upgrade-reboot on-event="/system/script/run firmware-upgrade-reboot;" start-time=startup;

Enjoy firmware being up to date and in sync with RouterOS.

See also
--------

* [Notify on RouterOS update](check-routeros-update.md)
* [Manage system update](packages-update.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
