Update tunnelbroker configuration
=================================

[◀ Go back to main README](../README.md)

Description
-----------

Connecting to [tunnelbroker.net](//tunnelbroker.net) from dynamic public
ip address requires the address to be sent to the remote, and to be set
locally. This script does both.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate update-tunnelbroker;

Installing [ppp-on-up](ppp-on-up.md) makes this script run when ever a ppp
connection is established.

Configuration
-------------

The configuration goes to interface's comment:

    / interface 6to4 set comment="tunnelbroker, user=user, pass=s3cr3t, id=12345" tunnelbroker;

Also enabling dynamic DNS in Mikrotik cloud is required:

    / ip cloud set ddns-enabled=yes;

See also
--------

* [Run scripts on ppp connection](ppp-on-up.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
