Find and remove access list duplicates
======================================

[◀ Go back to main README](../README.md)

🛈 This script can not be used on its own but requires the base installation.
See [main README](../README.md) for details.

Description
-----------

This script is supposed to run interactively to find and remove duplicate
entries in wireless access list.

Requirements and installation
-----------------------------

Depending on whether you use CAPsMAN (`/ caps-man`) or local wireless
interface (`/ interface wireless`) you need to install a different script.

For CAPsMAN:

    $ScriptInstallUpdate accesslist-duplicates.capsman;

For local interface:

    $ScriptInstallUpdate accesslist-duplicates.local;

Usage and invocation
--------------------

Run this script from a terminal:

    / system script run accesslist-duplicates.local;

![screenshot: example](accesslist-duplicates.d/01-example.avif)

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
