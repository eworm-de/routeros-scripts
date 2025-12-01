Update configuration on IPv6 prefix change
==========================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

With changing IPv6 prefix from ISP this script handles to update...

* ipv6 firewall address-list (prefixes (`/64`) and host addresses (`/128`))
* dns records

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ipv6-update;

Your ISP needs to provide an IPv6 prefix, your device receives it via dhcp:

    /ipv6/dhcp-client/add add-default-route=yes interface=ppp-isp pool-name=isp request=prefix script=ipv6-update;

Note this already adds this script as `script`. The pool name (here: "`isp`")
is important, we need it later.

Also this expects there is an address assigned from pool to an interface:

    /ipv6/address/add from-pool=isp interface=br-local;

Sometimes dhcp client is stuck on reconnect and needs to be released.
Installing [ppp-on-up](ppp-on-up.md) may solve this.

Configuration
-------------

As an address-list entry is mandatory a dynamic one is created automatically.
It is updated with current prefix and can be used in firewall rules.

Alternatively a static address-list entry can be used, where comment has to
be "`ipv6-pool-`" and actual pool name. Use what ever list is desired, and
create it with:

    /ipv6/firewall/address-list/add address=2003:cf:2f0f:de00::/56 comment=ipv6-pool-isp list=extern;

If the dynamic entry exists already you need to remove it before creating
the static one..

Address list entries for specific interfaces can be updated as well. The
interface needs to get its address from pool `isp` and the address list entry
has to be associated to an interface in comment:

    /ipv6/firewall/address-list/add address=2003:cf:2f0f:de01::/64 comment="ipv6-pool-isp, interface=br-local" list=local;

Updating address list entries with host addresses works as well, the new
prefix is combinded with given suffix then:

    /ipv6/firewall/address-list/add address=2003:cf:2f0f:de01:e3e0:f8fa:8cd6:dbe1/128 comment="ipv6-pool-isp, interface=br-local" list=hosts;

Static DNS records need a special comment to be updated. Again it has to
start with "`ipv6-pool-`" and actual pool name, followed by a comma,
"`interface=`" and the name of interface this address is connected to:

    /ip/dns/static/add address=2003:cf:2f0f:de00:1122:3344:5566:7788 comment="ipv6-pool-isp, interface=br-local" name=test.example.com ttl=15m;

See also
--------

* [Run scripts on ppp connection](ppp-on-up.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
