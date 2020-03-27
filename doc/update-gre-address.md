Update GRE configuration with dynamic addresses
===============================================

[◀ Go back to main README](../README.md)

Description
-----------

Running a GRE tunnel over IPSec with IKEv2 is a common scenario. This is
easy to configure on client, but has an issue on server side: client IP
addresses are assigned dynamically via mode-config and have to be updated
for GRE interface.

This script handles the address updates and disables the interface if the
client is disconnected.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate update-gre-address;

... and add a scheduler to run the script periodically:

    / system scheduler add interval=30s name=update-gre-address on-event="/ system script run update-gre-address;" start-time=startup;

Configuration
-------------

The configuration goes to interface's comment. Add the client's IKEv2
certificate CN into the comment:

    / interface gre set comment="ikev2-client1" gre-client1;

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
