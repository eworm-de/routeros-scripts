Run other scripts on DHCP lease
===============================

[◀ Go back to main README](../README.md)

🛈 This script can not be used on its own but requires the base installation.
See [main README](../README.md) for details.

Description
-----------

This script is supposed to run from dhcp server as lease script. Currently
it does:

* run [collect-wireless-mac](collect-wireless-mac.md)
* run [dhcp-lease-comment](dhcp-lease-comment.md)
* run [dhcp-to-dns](dhcp-to-dns.md)
* run [hotspot-to-wpa](hotspot-to-wpa.md)

Note that installation order influences execution order. You may want to
install `dhcp-to-dns` before `collect-wireless-mac` for dns name in
notification.

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
