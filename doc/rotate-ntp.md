Rotate NTP servers
==================

[◀ Go back to main README](../README.md)

Description
-----------

RouterOS requires NTP servers to be configured by IP address. Servers from a
pool may appear and disappear, leaving broken NTP configuration.

This script allows to rotate IP addresses from a given pool.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate rotate-ntp;

Configuration
-------------

The configuration goes to `global-config-overlay`, this is the parameter:

* `NtpPool`: dns name of ntp server pool

Usage and invocation
--------------------

Just run the script to update the NTP configuration with actual IP
addresses from pool if required.

Alternatively a scheduler can be created:

    / system scheduler add interval=5d name=rotate-ntp on-event="/ system script run rotate-ntp;" start-time=startup;

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
