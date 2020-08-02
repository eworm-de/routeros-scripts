Create DNS records for DHCP leases
==================================

[◀ Go back to main README](../README.md)

Description
-----------

This script adds (and removes) dns records based on dhcp server leases.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate dhcp-to-dns;

Then run it from dhcp server as lease script. You may want to use
[lease-script](lease-script.md).

A scheduler cares about cleanup:

    / system scheduler add interval=15m name=dhcp-to-dns on-event="/ system script run dhcp-to-dns;" start-time=startup;

Configuration
-------------

On first run a disabled static dns record acting as marker (with comment
"`--- dhcp-to-dns above ---`") is added. Move this entry to define where new
entries are to be added.

The configuration goes to `global-config-overlay`, these are the parameters:

* `Domain`: the domain used for dns records
* `HostNameInZone`: whether or not to add the dhcp/dns server's hostname
* `PrefixInZone`: whether or not to add prefix `dhcp`
* `ServerNameInZone`: whether or not to add DHCP server name

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)
* [Comment DHCP leases with info from access list](dhcp-lease-comment.md)
* [Run other scripts on DHCP lease](lease-script.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
