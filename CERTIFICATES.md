Certificate name from browser
=============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](README.md)

All well known desktop, mobile and server operating systems come with a
certificate store that is populated with a set of well known and trusted
certificates, acting as *trust anchors*.

However RouterOS does not, still sometimes a specific certificate is
required to properly verify a chain of trust. One example is downloading
the scripts from this repository with `fetch` command, thus the very
first step of [installation](README.md#the-long-way-in-detail) is importing
the certificate.

The scripts can install additional certificates when required. This happens
from this repository if available, or from [mkcert.org ↗️](https://mkcert.org)
as a fallback.

Get the certificate's CommonName
--------------------------------

But how to determine what certificate may be required? Often easiest way
is to use a desktop browser to get that information. This demonstration uses
[Mozilla Firefox ↗️](https://www.mozilla.org/firefox/).

Let's assume we want to make sure the certificate for
[git.eworm.de](https://git.eworm.de/) is available. Open that page in the
browser, then click the *lock* icon in addressbar, followed by "*Connection
secure*".

![screenshot: dialog A](CERTIFICATES.d/01-dialog-A.avif)

The dialog will change, click "*More information*".

![screenshot: dialog B](CERTIFICATES.d/02-dialog-B.avif)

A new window opens, click the button "*View Certificate*". (That window
can be closed now.)

![screenshot: window](CERTIFICATES.d/03-window.avif)

A new tab opens, showing information on the server certificate and its
chain of trust. The leftmost certificate is what we are interested in.

![screenshot: certificate](CERTIFICATES.d/04-certificate.avif)

Now we know that "`ISRG Root X2`" is required, some scripts need just
that information.

Import a certificate by CommonName
----------------------------------

Running the function `$CertificateAvailable` with that name as parameter
makes sure the certificate is available in the device's store:

    $CertificateAvailable "ISRG Root X2";

If the certificate is actually available already nothing happens, and there
is no output. Otherwise the certificate is downloaded and imported.

If importing a certificate with that exact name fails a warning is given
and nothing is actually imported.

See also
--------

* [Download, import and update firewall address-lists](doc/fw-addr-lists.md)
* [Manage DNS and DoH servers from netwatch](doc/netwatch-dns.md)
* [Send notifications via Matrix](doc/mod/notification-matrix.md)
* [Send notifications via Ntfy](doc/mod/notification-ntfy.md)

---
[⬅️ Go back to main README](README.md)  
[⬆️ Go back to top](#top)
