Renew certificates and notify on expiration
===========================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.12-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script tries to download and renew certificates, then notifies about
certificates that are still about to expire.

### Sample notification

![check-certificates notification](check-certificates.d/notification.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate check-certificates;

Configuration
-------------

For automatic download and renewal of certificates you need configuration
in `global-config-overlay`, these are the parameters:

* `CertRenewPass`: an array of passphrases to try
* `CertRenewTime`: on what remaining time to try a renew
* `CertRenewUrl`: the url to download certificates from
* `CertWarnTime`: on what remaining time to warn via notification

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Certificates on the web server should be named by their common name, like
`CN.pem` (`PEM` format) or`CN.p12` (`PKCS#12` format). Alternatively any
subject alternative name (aka *Subject Alt Name* or *SAN*) can be used.

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

Usage and invocation
--------------------

Just run the script:

    /system/script/run check-certificates;

... or create a scheduler for periodic execution:

    /system/scheduler/add interval=1d name=check-certificates on-event="/system/script/run check-certificates;" start-time=startup;


Tips & Tricks
-------------

### Schedule at startup

The script checks for full connectivity before acting, so scheduling at
startup is perfectly valid:

    /system/scheduler/add name=check-certificates@startup on-event="/system/script/run check-certificates;" start-time=startup;

### Initial import

Given you have a certificate on you server, you can use `check-certificates`
for the initial import. Just create a *dummy* certificate with short lifetime
that matches criteria to be renewed:

    /certificate/add name=example.com common-name=example.com days-valid=1;
    /certificate/sign example.com;
    /system/script/run check-certificates;

See also
--------

* [Renew locally issued certificates](certificate-renew-issued.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
