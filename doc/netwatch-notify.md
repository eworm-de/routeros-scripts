Notify on host up and down
==========================

[◀ Go back to main README](../README.md)

Description
-----------

This script sends notifications about host UP and DOWN events. In comparison
to just netwatch (`/ tool netwatch`) and its `up-script` and `down-script`
this script implements a simple state machine. Host down events are triggered
only if the host is down for several checks to avoid false alerts.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate netwatch-notify;

Then add a scheduler to run it periodically:

    / system scheduler add interval=1m name=netwatch-notify on-event="/ system script run netwatch-notify;" start-time=startup;

Configuration
-------------

The hosts to be checked have to be added to netwatch with specific comment:

    / tool netwatch add comment="notify, hostname=example.com" host=[ :resolve "example.com" ] timeout=5s;

It is possible to run an up hook command (`up-hook`) or down hook command
(`down-hook`) when a notification is triggered. This has to be added in
comment:

    / tool netwatch add comment="notify, hostname=poe-device, down-hook=/ interface ethernet poe power-cycle en21;" host=10.0.0.20 timeout=5s;

Also notification settings are required for e-mail and telegram.

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
