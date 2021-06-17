Notify about health state
=========================

[◀ Go back to main README](../README.md)

🛈 This script can not be used on its own but requires the base installation.
See [main README](../README.md) for details.

Description
-----------

This script is run from scheduler periodically, sending notification on
health related events:

* voltage jumps up or down more than configured threshold
* power supply failed or recovered
* temperature is above or below threshold

Note that bad initial state will not trigger an event.

Only sensors available in hardware can be checked. See what your
hardware supports:

    / system health print;

### Sample notifications

#### Voltage

![check-health notification voltage](notifications/check-health-voltage.svg)

#### Temperature

![check-health notification](notifications/check-health-temperature-high.svg)  
![check-health notification](notifications/check-health-temperature-ok.svg)

#### PSU state

![check-health notification](notifications/check-health-psu-fail.svg)  
![check-health notification](notifications/check-health-psu-ok.svg)

Requirements and installation
-----------------------------

Just install the script and create a scheduler:

    $ScriptInstallUpdate check-health;
    / system scheduler add interval=1m name=check-health on-event="/ system script run check-health;" start-time=startup;

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `CheckHealthTemperature`: an array specifying temperature thresholds for sensors
* `CheckHealthVoltagePercent`: percentage value to trigger voltage jumps

Also notification settings are required for e-mail, matrix and/or telegram.

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
