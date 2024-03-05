Use WPA network with hotspot credentials
========================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

RouterOS supports an unlimited number of MAC address specific passphrases
for WPA encrypted wifi networks via access list. The idea of this script
is to transfer hotspot credentials to MAC address specific WPA passphrase.

Requirements and installation
-----------------------------

You need a properly configured hotspot on one (open) SSID and a WPA enabled
SSID with suffix "`-wpa`".

Then install the script.
Depending on whether you use `wifi` package (`/interface/wifi`)or legacy
wifi with CAPsMAN (`/caps-man`) you need to install a different script and
set it as `on-login` script in hotspot.

For `wifi`:

    $ScriptInstallUpdate hotspot-to-wpa.wifi;
    /ip/hotspot/user/profile/set on-login="hotspot-to-wpa.wifi" [ find ];

For legacy CAPsMAN:

    $ScriptInstallUpdate hotspot-to-wpa.capsman;
    /ip/hotspot/user/profile/set on-login="hotspot-to-wpa.capsman" [ find ];

### Automatic cleanup

With just `hotspot-to-wpa` installed the mac addresses will last in the
access list forever. Install the optional script for automatic cleanup
and add a scheduler.

For `wifi` (RouterOS 7.13 and later):

    $ScriptInstallUpdate hotspot-to-wpa-cleanup.wifi,lease-script; 
    /system/scheduler/add interval=1d name=hotspot-to-wpa-cleanup on-event="/system/script/run hotspot-to-wpa-cleanup.wifi;" start-time=startup;

For `wifiwave2` (up to RouterOS 7.12):

    $ScriptInstallUpdate hotspot-to-wpa-cleanup.wifiwave2,lease-script;
    /system/scheduler/add interval=1d name=hotspot-to-wpa-cleanup on-event="/system/script/run hotspot-to-wpa-cleanup.wifiwave2;" start-time=startup;

For legacy CAPsMAN:

    $ScriptInstallUpdate hotspot-to-wpa-cleanup.capsman,lease-script;
    /system/scheduler/add interval=1d name=hotspot-to-wpa-cleanup on-event="/system/script/run hotspot-to-wpa-cleanup.capsman;" start-time=startup;

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
* `passphrase` or `private-passphrase`: do **not** use passphrase from
  hotspot's user credentials, but given one - or unset (use default
  passphrase) with special word `ignore`
* `ssid-regexp`: set a different SSID regular expression to match
* `vlan-id`: connect device to specific VLAN
* `vlan-mode`: set the VLAN mode for device

For a hotspot called `example` the template could look like this.
For `wifi`:

    /interface/wifi/access-list/add comment="hotspot-to-wpa template example" disabled=yes passphrase="ignore" ssid-regexp="^example\$" vlan-id=10;

For legacy CAPsMAN:

    /caps-man/access-list/add comment="hotspot-to-wpa template example" disabled=yes private-passphrase="ignore" ssid-regexp="^example\$" vlan-id=10 vlan-mode=use-tag;

The same settings are available in hotspot user's comment and take precedence
over the template settings:

    /ip/hotspot/user/add comment="private-passphrase=ignore, ssid-regexp=^example\\\$, vlan-id=10, vlan-mode=use-tag" name=user password=v3ry-s3cr3t;

Usage and invocation
--------------------

Now let the users connect and login to the hotspot. After that the devices
(identified by MAC address) can connect to the WPA network, using the
passphrase from hotspot credentials.

See also
--------

* [Run other scripts on DHCP lease](lease-script.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
