Renew locally issued certificates
=================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.14-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script renews certificates issued by a local certificate authority (CA).
Optionally the certificates are exported with individual passphrases for
easy pick-up.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate certificate-renew-issued;

Configuration
-------------

The configuration goes to `global-config-overlay`, there is just one
parameter:

* `CertRenewPass`: an array holding individual passphrases for certificates

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Usage and invocation
--------------------

Run the script to renew certificates issued from a local CA.

    /system/script/run certificate-renew-issued;

Only scripts with a remaining lifetime of three weeks or less are renewed.
The old certificate is revoked automatically. If a passphrase for a specific
certificate is given in `CertRenewPass` the certificate is exported and
PKCS#12 file (`cert-issued/CN.p12`) can be found on device's storage.

See also
--------

* [Renew certificates and notify on expiration](check-certificates.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
