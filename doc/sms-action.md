Act on received SMS
===================

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

RouterOS can act on received SMS. Reboot the device from remote or do
whatever is required.

A broadband interface with SMS support is required.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate sms-action;

Configuration
-------------

The configuration goes to `global-config-overlay`, this is the only parameter:

* `SmsAction`: an array with pre-defined actions

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Then enable SMS actions:

    /tool/sms/set allowed-number=+491234567890 receive-enabled=yes secret=s3cr3t;

Usage and invocation
--------------------

Send a SMS from allowed number to your device's phone number:

    :cmd s3cr3t script sms-action action=reboot;

The value given by "`action=`" is one of the pre-defined actions from
`SmsAction`.

See also
--------

* [Forward received SMS](sms-forward.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
