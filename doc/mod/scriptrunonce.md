Download script and run it once
===============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.14-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds a function that downloads a script, checks for syntax
validity and runs it once.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/scriptrunonce;

Configuration
-------------

The optional configuration goes to `global-config-overlay`.

* `ScriptRunOnceBaseUrl`: base url, prepended to parameter
* `ScriptRunOnceUrlSuffix`: url suffix, appended to parameter

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

If the parameter passed to the function is not a complete URL (starting
with protocol `ftp://`, `http://`, `https://` or `sftp://`) the base-url is
prepended, and file extension `.rsc` and url-suffix are appended.

Usage and invocation
--------------------

The function `$ScriptRunOnce` expects an URL (or name if
`ScriptRunOnceBaseUrl` is given) pointing to a script as parameter.

    $ScriptRunOnce https://git.eworm.de/cgit/routeros-scripts/plain/doc/mod/scriptrunonce.d/hello-world.rsc;

![ScriptRunOnce](scriptrunonce.d/scriptrunonce.avif)

Giving multiple scripts is possible, separated by comma.

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
