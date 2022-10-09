Update tunnelbroker configuration
=================================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

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

    /interface/6to4/set comment="tunnelbroker, user=user, id=12345, pass=s3cr3t" tunnelbroker;

You should know you user name from login. The `id` is the tunnel's numeric
id, `pass` is the *update key* found on the tunnel's advanced tab.

See also
--------

* [Run scripts on ppp connection](ppp-on-up.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
