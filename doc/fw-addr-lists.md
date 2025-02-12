Download, import and update firewall address-lists
==================================================

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

This script downloads, imports and updates firewall address-lists. Its main
purpose is to block attacking ip addresses, spam hosts, command-and-control
servers and similar malicious entities. The default configuration contains a
[collective list by GitHub user @stamparm](https://github.com/stamparm/ipsum),
lists from [dshield.org](https://dshield.org/) and
[blocklist.de](https://www.blocklist.de/), and lists from
[spamhaus.org](https://spamhaus.org/) are prepared.

The address-lists are updated in place, so after initial import you will not
see situation when the lists are not populated.

To mitigate man-in-the-middle attacks with altered lists the server's
certificate is checked.

> ⚠️ **Warning**: The script does not limit the size of a list, but keep in
> mind that huge lists can exhaust your device's resources (RAM and CPU),
> and may take a long time to process.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate fw-addr-lists;

And add two schedulers, first one for initial import after startup, second
one for subsequent updates:

    /system/scheduler/add name="fw-addr-lists@startup" start-time=startup on-event="/system/script/run fw-addr-lists;";
    /system/scheduler/add name="fw-addr-lists" start-time=startup interval=2h on-event="/system/script/run fw-addr-lists;";

> ℹ️ **Info**: Modify the interval to your needs, but it is recommended to
> use less than half of the configured timeout for expiration.

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `FwAddrLists`: a list of firewall address-lists to download and import
* `FwAddrListTimeOut`: the timeout for expiration without renew

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Naming a certificate for a list makes the script verify the server
certificate, so you should add that if possible. You may want to find the
[certificate name from browser](../CERTIFICATES.md).

Create firewall rules to process the packets that are related to addresses
from address-lists.

### IPv4 rules

This rejects the packets from and to IPv4 addresses listed in
address-list `block`.

    /ip/firewall/filter/add chain=input src-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ip/firewall/filter/add chain=forward src-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ip/firewall/filter/add chain=forward dst-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ip/firewall/filter/add chain=output dst-address-list=block action=reject reject-with=icmp-admin-prohibited;

You may want to have an address-list to allow specific addresses, as prepared
with a list `allow`. In fact you can use any list name, just change the
default ones or add your own - matching in configuration and firewall rules.

    /ip/firewall/filter/add chain=input src-address-list=allow action=accept;
    /ip/firewall/filter/add chain=forward src-address-list=allow action=accept;
    /ip/firewall/filter/add chain=forward dst-address-list=allow action=accept;
    /ip/firewall/filter/add chain=output dst-address-list=allow action=accept;

Modify these for your needs, but **most important**: Move the rules up in
chains and make sure they actually take effect as expected!

Alternatively handle the packets in firewall's raw section if you prefer:

    /ip/firewall/raw/add chain=prerouting src-address-list=block action=drop;
    /ip/firewall/raw/add chain=prerouting dst-address-list=block action=drop;
    /ip/firewall/raw/add chain=output dst-address-list=block action=drop;

> ⚠️ **Warning**: Just again... The order of firewall rules is important. Make
> sure they actually take effect as expected!

### IPv6 rules

These are the same rules, but for IPv6. 

Reject packets in address-list `block`:

    /ipv6/firewall/filter/add chain=input src-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ipv6/firewall/filter/add chain=forward src-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ipv6/firewall/filter/add chain=forward dst-address-list=block action=reject reject-with=icmp-admin-prohibited;
    /ipv6/firewall/filter/add chain=output dst-address-list=block action=reject reject-with=icmp-admin-prohibited;

Allow packets in address-list `allow`:

    /ipv6/firewall/filter/add chain=input src-address-list=allow action=accept;
    /ipv6/firewall/filter/add chain=forward src-address-list=allow action=accept;
    /ipv6/firewall/filter/add chain=forward dst-address-list=allow action=accept;
    /ipv6/firewall/filter/add chain=output dst-address-list=allow action=accept;

Drop packets in firewall's raw section:

    /ipv6/firewall/raw/add chain=prerouting src-address-list=block action=drop;
    /ipv6/firewall/raw/add chain=prerouting dst-address-list=block action=drop;
    /ipv6/firewall/raw/add chain=output dst-address-list=block action=drop;

> ⚠️ **Warning**: Just again... The order of firewall rules is important. Make
> sure they actually take effect as expected!

See also
--------

* [Certificate name from browser](../CERTIFICATES.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
