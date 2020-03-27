Manage remote logging
=====================

[◀ Go back to main README](../README.md)

Description
-----------

RouterOS supports sending log messages via network to a remote syslog server.
If the server is not available no log messages (with potentially sensitive
information) should be sent. This script disables remote logging by
availability.

Requirements and installation
-----------------------------

Let's assume there is a remote log action and associated logging rule:

    / system logging action set remote=10.0.0.1 [ find where name="remote" ];
    / system logging add action=remote topics=info;

Just install the script:

    $ScriptInstallUpdate netwatch-syslog;

... and create a netwatch matching the IP address from logging action above:

    / tool netwatch add down-script=netwatch-syslog host=10.0.0.1 up-script=netwatch-syslog;

All logging rules are disabled when host is down.

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
