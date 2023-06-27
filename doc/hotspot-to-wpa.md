Use WPA2 network with hotspot credentials
=========================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

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

    /ip/hotspot/user/profile/set on-login=hotspot-to-wpa [ find ];

### Automatic cleanup

With just `hotspot-to-wpa` installed the mac addresses will last in the
access list forever. Install the optional script for automatic cleanup:

    $ScriptInstallUpdate hotspot-to-wpa-cleanup,lease-script;

Create a scheduler:

    /system/scheduler/add interval=1d name=hotspot-to-wpa-cleanup on-event="/system/script/run hotspot-to-wpa-cleanup;" start-time=startup;

And add the lease script and matcher comment to your wpa interfaces' dhcp
server. You can add more information to the comment, separated by comma. In
this example the server is called `hotspot-to-wpa`.

    /ip/dhcp-server/set lease-script=lease-script comment="hotspot-to-wpa=wpa" hotspot-to-wpa;

You can specify the timeout after which a device is removed from leases and
access-list. The default is four weeks.

    /ip/dhcp-server/set lease-script=lease-script comment="hotspot-to-wpa=wpa, timeout=2w" hotspot-to-wpa;

Configuration
-------------

On first run a disabled access list entry acting as marker (with comment
"`--- hotspot-to-wpa above ---`") is added. Move this entry to define where new
entries are to be added.

Create hotspot login credentials:

    /ip/hotspot/user/add comment="Test User 1" name=user1 password=v3ry;
    /ip/hotspot/user/add comment="Test User 2" name=user2 password=s3cr3t;

This also works with authentication via radius, but is limited then:
Additional information is not available, including the password.

Additionally templates can be created to give more options for access list:

* `action`: set to `reject` to ignore logins on that hotspot
* `private-passphrase`: do **not** use passphrase from hotspot's user
  credentials, but given one - or unset (use default passphrase) with
  special word `ignore`
* `ssid-regexp`: set a different SSID regular expression to match
* `vlan-id`: connect device to specific VLAN
* `vlan-mode`: set the VLAN mode for device

For a hotspot called `example` the template could look like this:

    /caps-man/access-list/add comment="hotspot-to-wpa template example" disabled=yes private-passphrase="ignore" ssid-regexp="^example\$" vlan-id=10 vlan-mode=use-tag;

The same settings are available in hotspot user's comment and take precedence
over the template settings:

    /ip/hotspot/user/add comment="private-passphrase=ignore, ssid-regexp=^example\\\$, vlan-id=10, vlan-mode=use-tag" name=user password=v3ry-s3cr3t;

Usage and invocation
--------------------

Now let the users connect and login to the hotspot. After that the devices
(identified by MAC address) can connect to the WPA2 network, using the
passphrase from hotspot credentials.

See also
--------

* [Run other scripts on DHCP lease](lease-script.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
