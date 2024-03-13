Notify on host up and down
==========================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15beta4-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script sends notifications about host UP and DOWN events. In comparison
to just netwatch (`/tool/netwatch`) and its `up-script` and `down-script`
this script implements a simple state machine and dependency model. Host
down events are triggered only if the host is down for several checks and
optional parent host is not down to avoid false alerts.

### Sample notifications

![netwatch-notify notification down](netwatch-notify.d/notification-01-down.avif)  
![netwatch-notify notification up](netwatch-notify.d/notification-02-up.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate netwatch-notify;

Then add a scheduler to run it periodically:

    /system/scheduler/add interval=1m name=netwatch-notify on-event="/system/script/run netwatch-notify;" start-time=startup;

Configuration
-------------

The hosts to be checked have to be added to netwatch with specific comment:

    /tool/netwatch/add comment="notify, name=example.com" host=[ :resolve "example.com" ];

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

### Hooks

It is possible to run an up hook command (`up-hook`) or down hook command
(`down-hook`) when a notification is triggered. This has to be added in
comment, note that some characters need extra escaping:

    /tool/netwatch/add comment=("notify, name=device, down-hook=/interface/ethernet \\{ disable \\\"en2\\\"; enable \\\"en2\\\"; \\}") host=10.0.0.20;

Also there is a `pre-down-hook` that fires at two thirds of failed checks
required for the notification. The idea is to fix the issue before a
notification is sent.

Getting the escaping right may be troublesome. Please consider adding a
script in `/system/script`, then running that from hook.

### Count threshould

The count threshould (default is 5 checks) is configurable as well:

    /tool/netwatch/add comment="notify, name=example.com, count=10" host=104.18.144.11;

### Parents & dependencies

If the host is behind another checked host add a dependency, this will
suppress notification if the parent host is down:

    /tool/netwatch/add comment="notify, name=gateway" host=93.184.216.1;
    /tool/netwatch/add comment="notify, name=example.com, parent=gateway" host=93.184.216.34;

Note that every configured parent in a chain increases the check count
threshould by one.

### Update from DNS

The host address can be updated dynamically. Give extra parameter `resolve`
with a resolvable name:

    /tool/netwatch/add comment="notify, name=example.com, resolve=example.com";

This supports multiple A or AAAA records for a name just fine, even a CNAME
to those. An update happens only if no more record with the configured host
address is found.

### No notification on host down

Also suppressing the notification on host down is possible with parameter
`no-down-notification`. This may be desired for devices that are usually
powered off, but accessibility is of interest.

    /tool/netwatch/add comment="notify, name=printer, no-down-notification" host=10.0.0.30;

Go and get your coffee ☕️ before sending the print job.

### No log on failed resolve

A message is writting to log after three failed attemts to resolve a host.
However this can cause some noise for hosts that are expected to have
failures, for example when the name is dynamically added by
[`dhcp-to-dns`](dhcp-to-dns.md). This can be suppressed:

    /tool/netwatch/add comment="notify, name=client, resolve=client.dhcp.example.com, no-resolve-fail" host=10.0.0.0;

### Add a note in notification

For some extra information it is possible to add a text note. This is
included verbatim into the notification.

    /tool/netwatch/add comment="notify, name=example, note=Do not touch!" host=10.0.0.31;

### Add a link in notification

It is possible to add a link in notification, that is added below the
formatted notification text.

    /tool/netwatch/add comment="notify, name=example.com, resolve=example.com, link=https://example.com/";

Tips & Tricks
-------------

### One of several hosts

Sometimes it is sufficient if one of a number of hosts is available. You can
make `netwatch-notify` check for that by adding several items with same
`name`. Note that `count` has to be multiplied to keep the actual time.

    /tool/netwatch/add comment="notify, name=service, count=10" host=10.0.0.10;
    /tool/netwatch/add comment="notify, name=service, count=10" host=10.0.0.20;

### Checking internet connectivity

Sometimes you can not check your gateway for internet connectivity, for
example when it does not respond to pings or has a dynamic address. You could
check `1.1.1.1` (Cloudflare DNS), `9.9.9.9` (Quad-nine DNS), `8.8.8.8`
(Google DNS) or any other reliable address that indicates internet
connectivity.

    /tool/netwatch/add comment="notify, name=internet" host=1.1.1.1;

A target like this suits well to be parent for other checks.

    /tool/netwatch/add comment="notify, name=example.com, parent=internet" host=93.184.216.34;

### Checking specific ISP

Having several ISPs for redundancy a failed link may go unnoticed without
proper monitoring. You can use routing-mark to monitor specific connections.
Create a route and firewall mangle rule.

    /routing/table/add fib name=via-isp1;
    /ip/route/add distance=1 gateway=isp1 routing-table=via-isp1;
    /ip/firewall/mangle/add action=mark-routing chain=output new-routing-mark=via-isp1 dst-address=1.0.0.1 passthrough=yes;

Finally monitor the address with `netwatch-notify`.

    /tool/netwatch/add comment="notify, name=quad-one via isp1" host=1.0.0.1;

Note that *all* traffic to the given address is routed that way. In case of
link failure this address is not available, so use something reliable but
non-essential. In this example the address `1.0.0.1` is used, the same service
(Cloudflare DNS) is available at `1.1.1.1`.

### Use in combination with DNS and DoH management

Netwatch entries can be created to work with both - this script and
[netwatch-dns](netwatch-dns.md). Just give options for both:

    /tool/netwatch/add comment="doh, notify, name=cloudflare-dns" host=1.1.1.1;

See also
--------

* [Manage DNS and DoH servers from netwatch](netwatch-dns.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
