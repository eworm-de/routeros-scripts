Create DNS records for DHCP leases
==================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.16-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

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

The configuration goes to dhcp server's network definition. The domain is
used to form the dns name:

    /ip/dhcp-server/network/add address=10.0.0.0/24 domain=example.com;

A bound lease for mac address `00:11:22:33:44:55` with ip address
`10.0.0.50` would result in an A record `00-11-22-33-44-55.example.com`
pointing to the given ip address.

Additional options can be given from comment, to add an extra level in
dns name or define a different domain.

    /ip/dhcp-server/network/add address=10.0.0.0/24 domain=example.com comment="domain=another-domain.com, name-extra=dhcp";

This example would result in name `00-11-22-33-44-55.dhcp.another-domain.com`
for the same lease.

If no domain is found in dhcp server's network definition a fallback from
`global-config-overlay` is used. This is the parameter:

* `Domain`: the domain used for dns records

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

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
