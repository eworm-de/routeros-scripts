Run rolling CAP upgrades from CAPsMAN
=====================================

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

CAPsMAN can upgrade CAP devices. This script runs a rolling upgrade for
out-of-date CAP devices. The idea is to have just a fraction of devices
reboot at a time, having the others to serve wireless connectivity.

Note that the script does not wait for the CAPs to reconnect, it just defers
the upgrade commands. The more CAPs you have the more will upgrade in
parallel.

Requirements and installation
-----------------------------

Just install the script on CAPsMAN device.
Depending on whether you use `wifi` package (`/interface/wifi`) or legacy
wifi with CAPsMAN (`/caps-man`) you need to install a different script.

For `wifi`:

    $ScriptInstallUpdate capsman-rolling-upgrade.wifi;

For legacy CAPsMAN:

    $ScriptInstallUpdate capsman-rolling-upgrade.capsman;

Usage and invocation
--------------------

This script is intended as an add-on to
[capsman-download-packages](capsman-download-packages.md), being invoked by
that script when required.

Alternatively run it manually:

    /system/script/run capsman-rolling-upgrade.wifi;

See also
--------

* [Download packages for CAP upgrade from CAPsMAN](capsman-download-packages.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
