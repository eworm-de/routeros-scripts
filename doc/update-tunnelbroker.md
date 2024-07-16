Update tunnelbroker configuration
=================================

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

Connecting to [tunnelbroker.net](//tunnelbroker.net) from dynamic public
ip address requires the address to be sent to the remote, and to be set
locally. This script does both.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate update-tunnelbroker;

Installing [ppp-on-up](ppp-on-up.md) makes this script run when ever a ppp
connection is established.

Configuration
-------------

The configuration goes to interface's comment:

    /interface/6to4/set comment="tunnelbroker, user=user, id=12345, pass=s3cr3t" tunnelbroker;

You should know you user name from login. The `id` is the tunnel's numeric
id, `pass` is the *update key* found on the tunnel's advanced tab.

See also
--------

* [Run scripts on ppp connection](ppp-on-up.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
