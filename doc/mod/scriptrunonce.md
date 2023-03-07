Download script and run it once
===============================

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
