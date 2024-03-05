Use wireless network with daily psk
===================================

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
[trix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
