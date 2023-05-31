Renew certificates and notify on expiration
===========================================

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

Certificates on the web server should be named by their common name, like
`CN.pem` (`PEM` format) or`CN.p12` (`PKCS#12` format). Alternatively any
subject alternative name (aka *Subject Alt Name* or *SAN*) can be used.

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md) and/or
[telegram](mod/notification-telegram.md).

Usage and invocation
--------------------

Just run the script:

    /system/script/run check-certificates;

... or create a scheduler for periodic execution:

    /system/scheduler/add interval=1d name=check-certificates on-event="/system/script/run check-certificates;" start-time=startup;


Tips & Tricks
-------------

The script checks for full connectivity before acting, so scheduling at
startup is perfectly valid:

    /system/scheduler/add name=check-certificates@startup on-event="/system/script/run check-certificates;" start-time=startup;

See also
--------

* [Renew locally issued certificates](certificate-renew-issued.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
