Run other scripts on DHCP lease
===============================

[◀ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is supposed to run from dhcp server as lease script. On a dhcp
lease it runs each script containing the following line, where `##` is a
decimal number for ordering:

    # provides: lease-script, order=##

Currently it runs if available, in order:

* [dhcp-to-dns](dhcp-to-dns.md)
* [collect-wireless-mac](collect-wireless-mac.md)
* [dhcp-lease-comment](dhcp-lease-comment.md)
* `hotspot-to-wpa-cleanup`, which is an optional cleanup script
  of [hotspot-to-wpa](hotspot-to-wpa.md)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate lease-script;

... and add it as `lease-script` to your dhcp server:

    / ip dhcp-server set lease-script=lease-script [ find ];

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)
* [Comment DHCP leases with info from access list](dhcp-lease-comment.md)
* [Create DNS records for DHCP leases](dhcp-to-dns.md)
* [Use WPA2 network with hotspot credentials](hotspot-to-wpa.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
