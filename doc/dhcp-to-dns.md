Create DNS records for DHCP leases
==================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script adds (and updates & removes) dns records based on dhcp server
leases. An A record based on mac address is created for all bound lease,
additionally a CNAME record is created from host name if available.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate dhcp-to-dns;

Then run it from dhcp server as lease script. You may want to use
[lease-script](lease-script.md).

A scheduler cares about cleanup:

    /system/scheduler/add interval=15m name=dhcp-to-dns on-event="/system/script/run dhcp-to-dns;" start-time=startup;

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

### Host name from DHCP lease comment

Overwriting the host name from dhcp lease comment is supported, just add
something like `hostname=new-hostname` in comment, and separate it by comma
from other information if required:

    /ip/dhcp-server/lease/add address=10.0.0.50 comment="my device, hostname=new-hostname" mac-address=00:11:22:33:44:55 server=dhcp;

Note this information can be configured in wireless access list with
[dhcp-lease-comment](dhcp-lease-comment.md), though it comes with a delay
then due to script execution order. Decrease the scheduler interval to
reduce the effect.

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)
* [Comment DHCP leases with info from access list](dhcp-lease-comment.md)
* [Create DNS records for IPSec peers](ipsec-to-dns.md)
* [Run other scripts on DHCP lease](lease-script.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
