Renew locally issued certificates
=================================

[◀ Go back to main README](../README.md)

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

Usage and invocation
--------------------

Run the script to renew certificates issued from a local CA.

    / system script run certificate-renew-issued;

Only scripts with a remaining lifetime of three weeks or less are renewed.
The old certificate is revoked automatically. If a passphrase for a specific
certificate is given in `CertRenewPass` the certificate is exported and
PKCS#12 file (`cert-issued/CN.p12`) can be found on device's storage.

See also
--------

* [Renew certificates and notify on expiration](check-certificates.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
