Send notification with early errors
===================================

[◀ Go back to main README](../README.md)

Description
-----------

RouterOS supports sending log messages via e-mail or to a syslog server.
However this does not work early after boot if network connectivity is not
yet established. For example log messages about reboot without proper
shutdown may be missed:

> router rebooted without proper shutdown, probably power outage

The script collects log messages with severity `error` and sends a
notification.

Requirements and installation
-----------------------------

Just install this script and [global-wait](global-wait.md):

    $ScriptInstallUpdate early-errors,global-wait;

... and add a scheduler:

    / system scheduler add name=early-erros on-event=":global WaitFullyConnected; / system script { run global-wait; \$WaitFullyConnected; run early-errors; }" start-time=startup;

Configuration
-------------

The notifications just require notification settings for e-mail and telegram.

See also
--------

* [Wait for configuration und functions](global-wait.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
