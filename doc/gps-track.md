Send GPS position to server
===========================

[◀ Go back to main README](../README.md)

Description
-----------

This script is supposed to run periodically from scheduler and send GPS
position data to a server for tracking.

A hardware GPS antenna is required.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate gps-track;

... and create a scheduler:

    / system scheduler add interval=1m name=gps-track on-event="/ system script run gps-track;" start-time=startup;

Configuration
-------------

The configuration goes to `global-config-overlay`, the only parameter is:

* `GpsTrackUrl`: the url to send json data to

The configured coordinate format (see `/ system gps`) defines the format
sent to the server.

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
