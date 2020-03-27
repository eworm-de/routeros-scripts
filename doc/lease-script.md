Run other scripts on DHCP lease
===============================

[◀ Go back to main README](../README.md)

Description
-----------

This script is supposed to run from dhcp server as lease script. Currently
it does:

* run [dhcp-to-dns](dhcp-to-dns.md)
* run [collect-wireless-mac](collect-wireless-mac.md)
* run [dhcp-lease-comment](dhcp-lease-comment.md)

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

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
