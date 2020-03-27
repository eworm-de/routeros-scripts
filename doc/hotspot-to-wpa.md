Use WPA2 network with hotspot credentials
=========================================

[◀ Go back to main README](../README.md)

Description
-----------

RouterOS supports an unlimited number of MAC address specific passphrases
for WPA2 encrypted wifi networks via access list. The idea of this script
is to transfer hotspot credentials to MAC address specific WPA2 passphrase.

Requirements and installation
-----------------------------

You need a properly configured hotspot on one (open) SSID and a WP2 enabled
SSID with suffix "`-wpa`".

Then install the script:

    $ScriptInstallUpdate hotspot-to-wpa;

Configure your hotspot to use this script as `on-login` script:

    / ip hotspot user profile set on-login=hotspot-to-wpa [ find ];

Configuration
-------------

On first run a disabled access list entry acting as marker (with comment
"`--- hotspot-to-wpa above ---`") is added. Move this entry to define where new
entries are to be added.

Usage and invocation
--------------------

Create hotspot login credentials:

    / ip hotspot user add add comment="Test User 1" name=user1 password=v3ry;
    / ip hotspot user add add comment="Test User 2" name=user2 password=s3cr3t;

Now let the users connect and login to the hotspot. After that the devices
(identified by MAC address) can connect to the WPA2 network, using the
passphrase from hotspot credentials.

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
