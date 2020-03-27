Comment DHCP leases with info from access list
==============================================

[◀ Go back to main README](../README.md)

Description
-----------

This script adds comments to dynamic dhcp server leases. Infos are taken
from wireless access list.

Requirements and installation
-----------------------------

Depending on whether you use CAPsMAN (`/ caps-man`) or local wireless
interface (`/ interface wireless`) you need to install a different script.

For CAPsMAN:

    $ScriptInstallUpdate dhcp-lease-comment.capsman;

For local interface:

    $ScriptInstallUpdate dhcp-lease-comment.local;

Configuration
-------------

Infos are taken from wireless access list. Add entries with proper comments
there. You may want to use [collect-wireless-mac](collect-wireless-mac.md)
to prepare entries.

Usage and invocation
--------------------

Run this script from a dhcp server as lease-script to update the comment
just after a new address is leased. You may want to use
[lease-script](lease-script.md).

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)
* [Create DNS records for DHCP leases](dhcp-to-dns.md)
* [Run other scripts on DHCP lease](lease-script.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
