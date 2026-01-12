Use wireless network with daily psk
===================================

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

This script is supposed to provide a wifi network which changes the
passphrase to a pseudo-random string daily.

### Sample notification

![daily-psk notification](daily-psk.d/notification.avif)

Requirements and installation
-----------------------------

Just install this script.

Depending on whether you use `wifi` package (`/interface/wifi`), legacy
wifi with CAPsMAN (`/caps-man`) or local wireless interface
(`/interface/wireless`) you need to install a different script and add
schedulers to run the script:

For `wifi`:

    $ScriptInstallUpdate daily-psk.wifi;
    /system/scheduler/add interval=1d name=daily-psk on-event="/system/script/run daily-psk.wifi;" start-time=03:00:00;
    /system/scheduler/add name=daily-psk@startup on-event="/system/script/run daily-psk.wifi;" start-time=startup;

For legacy CAPsMAN:

    $ScriptInstallUpdate daily-psk.capsman;
    /system/scheduler/add interval=1d name=daily-psk on-event="/system/script/run daily-psk.capsman;" start-time=03:00:00;
    /system/scheduler/add name=daily-psk@startup on-event="/system/script/run daily-psk.capsman;" start-time=startup;

For legacy local interface:

    $ScriptInstallUpdate daily-psk.local;
    /system/scheduler/add interval=1d name=daily-psk on-event="/system/script/run daily-psk.local;" start-time=03:00:00;
    /system/scheduler/add name=daily-psk@startup on-event="/system/script/run daily-psk.local;" start-time=startup;

These will update the passphrase on boot and nightly at 3:00.

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `DailyPskMatchComment`: pattern to match the wireless access list comment
* `DailyPskSecrets`: an array with pseudo random strings

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Then add an access list entry. For `wifi`:

    /interface/wifi/access-list/add comment="Daily PSK" ssid-regexp="-guest\$" passphrase="ToBeChangedDaily";

For legacy CAPsMAN:

    /caps-man/access-list/add comment="Daily PSK" ssid-regexp="-guest\$" private-passphrase="ToBeChangedDaily";

For legacy local interface:

    /interface/wireless/access-list/add comment="Daily PSK" interface=wl-daily private-pre-shared-key="ToBeChangedDaily";

Also notification settings are required for
[e-mail](mod/notification-email.md),
[gotify](mod/notification-gotify.md),
[trix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
