Run other scripts on IPv6 DHCP client lease
===========================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.19-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is supposed to run from IPv6 DHCP client as lease script. On a
DHCP leasse it runs each script containing the following line, where `##` is
a decimal number for ordering:

    # provides: dhcpv6-client-lease, order=##

The lease script is started with some variables injected, but these are not
available in child scripts. However this script makes these variables
available with a global variable. This code is required in child script:

    :global EitherOr;
    
    :global DHCPv6ClientLeaseVars;
    
    :local NaAddress [ $EitherOr $"na-address" ($DHCPv6ClientLeaseVars->"na-address") ];
    :local NaValid [ $EitherOr $"na-valid" ($DHCPv6ClientLeaseVars->"na-valid") ];
    :local PdPrefix [ $EitherOr $"pd-prefix" ($DHCPv6ClientLeaseVars->"pd-prefix") ];
    :local PdValid [ $EitherOr $"pd-valid" ($DHCPv6ClientLeaseVars->"pd-valid") ];
    :local Options [ $EitherOr $"options" ($DHCPv6ClientLeaseVars->"options") ];

The values are available under different name then, use `$PdPrefix` instead
of `$"pd-prefix"`, and so on. The resulting script supports both, being a
lease script itself or being run as child.

Currently it runs if available, in order:

* [ipv6-update](ipv6-update.md)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate dhcpv6-client-lease;

... and add it as `lease-script` to your dhcp client:

    /ipv6/dhcp-client/set lease-script="dhcpv6-client-lease" [ find ];

See also
--------

* [Update configuration on IPv6 prefix change](ipv6-update.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
