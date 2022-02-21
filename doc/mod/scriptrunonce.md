Download script and run it once
===============================

[◀ Go back to main README](../../README.md)

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

Usage and invocation
--------------------

The function `$ScriptRunOnce` expects an url pointing to a script as parameter.

    $ScriptRunOnce https://git.eworm.de/cgit/routeros-scripts/plain/doc/mod/scriptrunonce.d/hello-world.rsc

![ScriptRunOnce](scriptrunonce.d/scriptrunonce.avif)

Giving multiple scripts is possible, separated by comma.

---
[◀ Go back to main README](../../README.md)  
[▲ Go back to top](#top)
