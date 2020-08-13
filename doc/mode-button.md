Mode button with multiple presses
=================================

[◀ Go back to main README](../README.md)

Description
-----------

These scripts extend the functionality of mode button. Instead of just one
you can trigger several actions by pressing the mode button several times.

The hardware needs to have a mode button, see
`/ system routerboard mode-button`. Starting with RouterOS 6.47beta60 you
can configure the reset button to act the same, see
`/ system routerboard reset-button`.

Requirements and installation
-----------------------------

Just install the scripts:

    $ScriptInstallUpdate mode-button-event,mode-button-scheduler;

Then configure the mode button to run `mode-button-event`:

    / system routerboard mode-button set enabled=yes on-event="/ system script run mode-button-event;";

To use the reset button instead:

    / system routerboard reset-button set enabled=yes on-event="/ system script run mode-button-event;";

Configuration
-------------

The configuration goes to `global-config-overlay`, the only parameter is:

* `ModeButton`: an array with defined actions

Usage and invocation
--------------------

Press the mode button. :)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
