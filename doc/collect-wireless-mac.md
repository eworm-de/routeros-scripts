Collect MAC addresses in wireless access list
=============================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script adds unknown MAC addresses of connected wireless devices to
address list. In addition a notification is sent.

By default the access list entry is disabled, but you can easily enable
and modify it to your needs.

### Sample notification

![collect-wireless-mac notification](collect-wireless-mac.d/notification.avif)

Requirements and installation
-----------------------------

Depending on whether you use `wifi` package (`/interface/wifi`), legacy
wifi with CAPsMAN (`/caps-man`) or local wireless interface
(`/interface/wireless`) you need to install a different script.

For `wifi`:

    $ScriptInstallUpdate collect-wireless-mac.wifi;

For legacy CAPsMAN:

    $ScriptInstallUpdate collect-wireless-mac.capsman;

For legacy local interface:

    $ScriptInstallUpdate collect-wireless-mac.local;

Configuration
-------------

On first run a disabled access list entry acting as marker (with comment
"`--- collected above ---`") is added. Move this entry to define where new
entries are to be added.

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

Usage and invocation
--------------------

Run this script from a dhcp server as lease-script to collect the MAC
address when a new address is leased. You may want to use
[lease-script](lease-script.md).

See also
--------

* [Comment DHCP leases with info from access list](dhcp-lease-comment.md)
* [Create DNS records for DHCP leases](dhcp-to-dns.md)
* [Run other scripts on DHCP lease](lease-script.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
