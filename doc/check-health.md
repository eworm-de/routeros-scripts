Notify about health state
=========================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script is run from scheduler periodically, sending notification on
health related events. Monitoring CPU and RAM utilization (available
processing and memory resources) works on all devices:

* high CPU utilization
* high RAM utilization (low available RAM)

With additional plugins functionality can be extended, depending on
sensors available in hardware:

* voltage jumps up or down more than configured threshold
* voltage drops below hard lower limit
* fan failed or recovered
* power supply failed or recovered
* temperature is above or below threshold

> ⚠️ **Warning**: Note that bad initial state will not trigger an event! For
> example rebooting a device that is already too hot will not trigger an
> alert on high temperature.

### Sample notifications

#### CPU utilization

![check-health notification cpu utilization high](check-health.d/notification-01-cpu-utilization-high.avif)  
![check-health notification cpu utilization ok](check-health.d/notification-02-cpu-utilization-ok.avif)

#### RAM utilization (low available RAM)

![check-health notification ram utilization high](check-health.d/notification-03-ram-utilization-high.avif)  
![check-health notification ram utilization ok](check-health.d/notification-04-ram-utilization-ok.avif)

#### Voltage

![check-health notification voltage](check-health.d/notification-05-voltage.avif)

#### Temperature

![check-health notification temperature high](check-health.d/notification-06-temperature-high.avif)  
![check-health notification temperature ok](check-health.d/notification-07-temperature-ok.avif)

#### PSU state

![check-health notification state fail](check-health.d/notification-08-state-fail.avif)  
![check-health notification state ok](check-health.d/notification-09-state-ok.avif)

Requirements and installation
-----------------------------

Just install the script and create a scheduler:

    $ScriptInstallUpdate check-health;
    /system/scheduler/add interval=53s name=check-health on-event="/system/script/run check-health;" start-time=startup;

> ℹ️ **Info**: Running lots of scripts simultaneously can tamper the
> precision of cpu utilization, escpecially on devices with limited
> resources. Thus an unusual interval is used here.

### Plugins

Additional plugins are available for sensors available in hardware. First
check what your hardware supports:

    /system/health/print;

Then install the plugin for *fan* and *power supply unit* *state*:

    $ScriptInstallUpdate check-health,check-health.d/state;

... or *temperature*:

    $ScriptInstallUpdate check-health,check-health.d/temperature;

... or *voltage*:

    $ScriptInstallUpdate check-health,check-health.d/voltage;

You can also combine the commands and install all or a subset of plugins
in one go:

    $ScriptInstallUpdate check-health,check-health.d/state,check-health.d/temperature,check-health.d/voltage;

Configuration
-------------

The configuration goes to `global-config-overlay`, these are the parameters:

* `CheckHealthTemperature`: an array specifying temperature thresholds for sensors
* `CheckHealthVoltageLow`: value (in volt*10) giving a hard lower limit
* `CheckHealthVoltagePercent`: percentage value to trigger voltage jumps

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Also notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
