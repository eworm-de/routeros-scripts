Manage IP addresses with bridge status
======================================

[◀ Go back to main README](../README.md)

Description
-----------

With RouterOS an IP address is always active, even if an interface is down.
Other venders handle this differently - and sometimes this behavior is
expected. This script mimics this behavior.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ip-addr-bridge;

... and make it run from scheduler:

    / system scheduler add name=ip-addr-bridge on-event="/ system script run ip-addr-bridge;" start-time=startup;

This will disable IP addresses on bridges without at lease one running port.
The IP address is enabled if at least one port is running.

Note that IP addresses on bridges without a single port (acting as loopback
interface) are ignored.

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
