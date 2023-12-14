Mode button with multiple presses
=================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script extend the functionality of mode button. Instead of just one
you can trigger several actions by pressing the mode button several times.

The hardware needs to have a mode button, see
`/system/routerboard/mode-button`. Starting with RouterOS 6.47beta60 you
can configure the reset button to act the same, see
`/system/routerboard/reset-button`.

Copy this code to terminal to check:

```
:if ([ :len [ /system/routerboard/mode-button/print as-value ] ] > 0) do={
  :put "Mode button is supported.";
} else={
  :if ([ :len [ /system/routerboard/reset-button/print as-value ] ] > 0) do={
    :put "Mode button is not supported, but reset button is.";
  } else={
    :put "Neither mode button nor reset button is supported.";
  }
}
```

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate mode-button;

Then configure the mode button to run `mode-button`:

    /system/routerboard/mode-button/set enabled=yes on-event="/system/script/run mode-button;";

To use the reset button instead:

    /system/routerboard/reset-button/set enabled=yes on-event="/system/script/run mode-button;";

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `ModeButton`: an array with defined actions
* `ModeButtonLED`: led to give visual feedback, `type` must be `on` or `off`

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Usage and invocation
--------------------

Press the mode button. 😜

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
