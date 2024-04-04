IP address calculation
======================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.13-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds functions for IP address calculation.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/ipcalc;

Usage and invocation
--------------------

### IPCalc

The function `$IPCalc` prints information to terminal, including:

* address
* netmask
* network in CIDR notation
* minimum host address
* maximum host address
* broadcast address

It expects an IP address in CIDR notation as argument.

    $IPCalc 192.168.88.1/24;

![IPCalc](ipcalc.d/ipcalc.avif)

### IPCalcReturn

The function `$IPCalcReturn` expects an IP address in CIDR notation as
argument as well. But it does not print to terminal, instead it returns
the information in a named array.

    :put ([ $IPCalcReturn  192.168.88.1/24 ]->"broadcast");

![IPCalcReturn](ipcalc.d/ipcalcreturn.avif)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
