Create DNS records for IPSec peers
==================================

[◀ Go back to main README](../README.md)

> 🛈 **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script adds (and removes) dns records based on IPSec peers and their
dynamic addresses from mode-config.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ipsec-to-dns;

This script is run from scheduler:

    / system scheduler add interval=1m name=ipsec-to-dns on-event="/ system script run ipsec-to-dns;" start-time=startup;

Configuration
-------------

On first run a disabled static dns record acting as marker (with comment
"`--- ipsec-to-dns above ---`") is added. Move this entry to define where new
entries are to be added.

The configuration goes to `global-config-overlay`, these are the parameters:

* `Domain`: the domain used for dns records
* `HostNameInZone`: whether or not to add the ipsec/dns server's hostname
* `PrefixInZone`: whether or not to add prefix `ipsec`

See also
--------

* [Create DNS records for DHCP leases](dns-to-dhcp.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
