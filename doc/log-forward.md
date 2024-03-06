Forward log messages via notification
=====================================

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

RouterOS itself supports sending log messages via e-mail or to a syslog
server (see `/system/logging`). This has some limitation, however:

* does not work early after boot if network connectivity is not
  yet established, or breaks intermittently
* lots of messages generate a flood of mails
* Matrix and Telegram are not supported

The script works around the limitations, for example it does:

* read from `/log`, including messages from early boot
* skip multi-repeated messages
* rate-limit itself to mitigate flooding
* forward via notification (which includes *e-mail*, *Matrix* and *Telegram*
  when installed and configured, see below)

It is intended to be run periodically from scheduler, then collects new
log messages and forwards them via notification.

### Sample notification

![log-forward notification](log-forward.d/notification.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate log-forward;

... and add a scheduler:

    /system/scheduler/add interval=1m name=log-forward on-event="/system/script/run log-forward;" start-time=startup;

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `LogForwardFilter`: define topics *not* to be forwarded
* `LogForwardFilterMessage`: define message text *not* to be forwarded
* `LogForwardInclude`: define topics to be forwarded (even if filter matches)
* `LogForwardIncludeMessage`: define message text to be forwarded (even if
  filter matches)

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

These patterns are matched as
[regular expressions](https://wiki.mikrotik.com/wiki/Manual:Regular_Expressions).
To forward **all** (ignoring severity) log messages with topics `account`
(which includes user logins) and `dhcp` you need something like:

    :global LogForwardInclude "(account|dhcp)";

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

Tips & Tricks
-------------

### Notification on reboot

You want to receive a notification on every device (re-)boot? Quite easy,
just add:

    :global LogForwardIncludeMessage "(^router rebooted)";

This will match on every log message beginning with `router rebooted`.

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
