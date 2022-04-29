Use WPA2 network with hotspot credentials
=========================================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

RouterOS supports an unlimited number of MAC address specific passphrases for WPA2 encrypted wifi networks via access list. The idea of this script is to transfer hotspot credentials to MAC address specific WPA2 passphrase.

Requirements and installation
-----------------------------

You need a properly configured hotspot on one  SSID. You can use either an open SSID and a WPA protected SSID or merge hotspot and WPA protection into one SSID. If you do the first reading warning further down.
To create a hotspot you can run the hotspot setup  `/ip hotspot/ setup` as described in [HotSpot (Captive portal) - RouterOS - MikroTik Documentation](https://help.mikrotik.com/docs/pages/viewpage.action?pageId=56459266)

In this script, is is assumed that the WPA protected SSID is suffixed with `"-wpa"` . 

Then install the script:

    $ScriptInstallUpdate hotspot-to-wpa;

Run the following command to that each user profile will use this script as `on-login` script. If you want to limit the scrip to a certain hotspot only adapt `find` to your needs.

    / ip hotspot user profile set on-login=hotspot-to-wpa [ find ];

### Warning, MAC randomization behaviour

As up to date smartphone randomize their mac adress, see [Use private Wi-Fi addresses on iPhone, iPad, iPod touch, and Apple Watch - Apple Support](https://support.apple.com/en-us/HT211227) and [MAC Randomization Behavior  | Android Open Source Project](https://source.android.com/devices/tech/connect/wifi-mac-randomization-behavior) for details, using two SSID can fail this dynamic WPA plus optional VLAN assignment. 


### Automatic clean-up

If a devices connects, any access list entry of this mac addresses with the comment `hotspot-to-wpa:` will be removed but still with just `hotspot-to-wpa` installed the mac addresses will last in the access list forever. Install the optional script for automatic clean-up:

    $ScriptInstallUpdate hotspot-to-wpa-cleanup,lease-script;

Create a scheduler:

    / system scheduler add interval=1d name=hotspot-to-wpa-cleanup on-event="/ system script run hotspot-to-wpa-cleanup;" start-time=startup;

And add the [lease-script](https://git.eworm.de/cgit/routeros-scripts/about/doc/lease-script.md) to at least your WPA interfaces' DHCP server to benefit from auto-commenting of leased IPs and run the automatic clean-up at each DHCP lease. It is recommended :

    / ip dhcp-server set lease-script=lease-script [ find where name~"wpa" ];

Configuration
-------------

On first run a disabled access list entry acting as marker (with comment "`--- hotspot-to-wpa above ---`") is added. Move this entry to define where new entries are to be added.

Create credentials for the hotspot. These credentials are used to connect to the WPA2 encrypted WiFi network after an initial login to the hotspot. The password defined to login into the hotspot is the same password the user shall use to login into the WPA protected SSID.

    / ip hotspot user add comment="Test User 1" name=user1 password=v3ry;
    / ip hotspot user add comment="Test User 2" name=user2 password=s3cr3t;

If there is not  any template in `/ caps-man access-list` it will create as below for the hotspot triggering the script. For a hotspot called `example` the template look like this:

    / caps-man access-list add comment="hotspot-to-wpa template example" disabled=yes

Additionally templates can be created to give more options for access list. If the template is not modified the script will search for SSIDs suffixed with "`-wpa`" and allow the users to connect to these SSIDS with password defined to login into the hotspot.  
If a user is only allowed to connect to a specific SSID and/or is to be assigned to a VLAN, a corresponding template must be created.

The templates can created either  in `/ caps-man access-list` or `/ ip hotspot user`.  The template in `/ ip hotspot user`  takes precedence over the template settings in `/ caps-man access-list`.

The options in templates are mostly as defined in [Access List - Wireless Interface - RouterOS - MikroTik Documentation](https://help.mikrotik.com/docs/display/ROS/Wireless+Interface#WirelessInterface-AccessList)) / [Access List - WifiWave2 - RouterOS - MikroTik Documentation](https://help.mikrotik.com/docs/display/ROS/WifiWave2#WifiWave2-AccessList) and are as follows:

* `action`: set to `reject` to ignore logins on that hotspot
* `private-passphrase`: do **not** use passphrase from hotspot's user credentials, but given one - or unset (use default passphrase) with
  special word `ignore` 
* `ssid-regexp`: define the SSID the user is allowed to connect
* `vlan-id`: connect device to specific VLAN
* `vlan-mode`: set the VLAN mode for device

### Template example 

For a hotspot called `example` the template could look like this:

    / caps-man access-list add comment="hotspot-to-wpa template example" disabled=yes private-passphrase="ignore" ssid-regexp="^example\$" vlan-id=10 vlan-mode=use-tag;

The same settings are available in hotspot user's comment and take precedence over the template settings:

    / ip hotspot user add comment="private-passphrase=ignore, ssid-regexp=^example\\\$, vlan-id=10, vlan-mode=use-tag" name=user password=v3ry-s3cr3t;

Usage and invocation
--------------------

Now let the users connect and login to the hotspot. After that the devices (identified by MAC address) can connect to the WPA2 network, using the
passphrase from hotspot credentials.

See also
--------

* [Run other scripts on DHCP lease](lease-script.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
