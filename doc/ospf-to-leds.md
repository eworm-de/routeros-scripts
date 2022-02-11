Visualize OSPF state via LEDs
=============================

[◀ Go back to main README](../README.md)

> 🛈 **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

Physical interfaces have their state LEDs, software-defined connectivity
does not. This script helps to visualize whether or not an OSPF instance
is running.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ospf-to-leds;

... and add a scheduler to run the script periodically:

    / system scheduler add interval=20s name=ospf-to-leds on-event="/ system script run ospf-to-leds;" start-time=startup;

Configuration
-------------

The configuration goes to OSPF instance's comment. To visualize state for
instance `default` via LED `user-led` set this:

    / routing ospf instance set default comment="ospf-to-leds, leds=user-led";

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
