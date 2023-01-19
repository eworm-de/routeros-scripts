Forward log messages via notification
=====================================

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

These patterns are matched as
[regular expressions](https://wiki.mikrotik.com/wiki/Manual:Regular_Expressions).
To forward **all** (ignoring severity) log messages with topics `account`
(which includes user logins) and `dhcp` you need something like:

    :global LogForwardInclude "(account|dhcp)";

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md) and/or
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
