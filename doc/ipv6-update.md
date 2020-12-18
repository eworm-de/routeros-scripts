Update configuration on IPv6 prefix change
==========================================

[◀ Go back to main README](../README.md)

Description
-----------

With changing IPv6 prefix from ISP this script handles to update...

* ipv6 firewall address-list
* dns records

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ipv6-update;

Your ISP needs to provide an IPv6 prefix, your device receives it via dhcp:

    / ipv6 dhcp-client add add-default-route=yes interface=ppp-isp pool-name=isp request=prefix script=ipv6-update;

Note this already adds this script as `script`. The pool name (here: "`isp`")
is important, we need it later.

Also this expects there is an address assigned from pool to an interface:

    / ipv6 address add from-pool=isp interface=br-local;

Sometimes dhcp client is stuck on reconnect and needs to be released.
Installing [ppp-on-up](ppp-on-up.md) may solve this.

Configuration
-------------

An address list entry is updated with current prefix and can be used in
firewall rules, comment has to be "`ipv6-pool-`" and actual pool name:

    / ipv6 firewall address-list add address=2003:cf:2f0f:de00::/56 comment=ipv6-pool-isp list=extern;

As this entry is mandatory it is created automatically if it does not exist,
with the comment also set for list.

Address list entries for specific interfaces can be updated as well. The
interface needs to get its address from pool `isp` and the address list entry
has to be associated to an interface in comment:

    / ipv6 firewall address-list add address=2003:cf:2f0f:de01::/64 comment="ipv6-pool-isp, interface=br-local" list=local;

Static DNS records need a special comment to be updated. Again it has to
start with "`ipv6-pool-`" and actual pool name, followed by a comma,
"`interface=`" and the name of interface this address is connected to:

    / ip dns static add address=2003:cf:2f0f:de00:1122:3344:5566:7788 comment="ipv6-pool-isp, interface=br-local" name=test.example.com ttl=15m;

See also
--------

* [Run scripts on ppp connection](ppp-on-up.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
