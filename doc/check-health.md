Notify about health state
=========================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is run from scheduler periodically, sending notification on
health related events:

* high CPU load
* voltage jumps up or down more than configured threshold or drops below limit
* power supply failed or recovered
* temperature is above or below threshold

Note that bad initial state will not trigger an event.

Monitoring CPU load works on all devices. Other than that only sensors
available in hardware can be checked. See what your hardware supports:

    /system/health/print;

### Sample notifications

#### CPU load

![check-health notification cpu load high](check-health.d/notification-01-cpu-load-high.avif)
![check-health notification cpu load ok](check-health.d/notification-02-cpu-load-ok.avif)

#### Voltage

![check-health notification voltage](check-health.d/notification-03-voltage.avif)

#### Temperature

![check-health notification temperature high](check-health.d/notification-04-temperature-high.avif)  
![check-health notification temperature ok](check-health.d/notification-05-temperature-ok.avif)

#### PSU state

![check-health notification psu fail](check-health.d/notification-06-psu-fail.avif)  
![check-health notification psu ok](check-health.d/notification-07-psu-ok.avif)

Requirements and installation
-----------------------------

Just install the script and create a scheduler:

    $ScriptInstallUpdate check-health;
    /system/scheduler/add interval=1m name=check-health on-event="/system/script/run check-health;" start-time=startup;

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `CheckHealthTemperature`: an array specifying temperature thresholds for sensors
* `CheckHealthVoltageLow`: value (in volt*10) giving a hard lower limit
* `CheckHealthVoltagePercent`: percentage value to trigger voltage jumps

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md) and/or
[telegram](mod/notification-telegram.md).

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
