IP address calculation
======================

[◀ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds functions for IP address calculation.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/ipcalc;

Usage and invocation
--------------------

### IPCalc

The function `$IPCalc` prints information to terminal, including:

* address
* netmask
* network in CIDR notation
* minimum host address
* maximum host address
* broadcast address

It expects an IP address in CIDR notation as argument.

    $IPCalc 192.168.88.1/24;

![IPCalc](ipcalc.d/ipcalc.avif)

### IPCalcReturn

The function `$IPCalcReturn` expects an IP address in CIDR notation as
argument as well. But it does not print to terminal, instead it returns
the information in a named array.

    :put ([ $IPCalcReturn  192.168.88.1/24 ]->"broadcast");

![IPCalcReturn](ipcalc.d/ipcalcreturn.avif)

---
[◀ Go back to main README](../../README.md)  
[▲ Go back to top](#top)
