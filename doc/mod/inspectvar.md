Inspect variables
=================

[◀ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

RouterOS handles not just scalar variables, but also arrays - even nested.
This module adds a function to inspect variables.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/inspectvar;

Usage and invocation
--------------------

Call the function `$InspectVar` with a variable as parameter:

    $InspectVar $ModeButton;

![InspectVar](inspectvar.d/inspectvar.avif)

---
[◀ Go back to main README](../../README.md)  
[▲ Go back to top](#top)
