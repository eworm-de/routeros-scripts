Manage LEDs dark mode
=====================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

Description
-----------

These scripts control LEDs mode and allow to run your device
completely dark. Hardware support for dark mode is required.

Requirements and installation
-----------------------------

Just install the scripts:

    $ScriptInstallUpdate leds-day-mode,leds-night-mode,leds-toggle-mode;

Usage and invocation
--------------------

To switch the device to dark mode:

    /system/script/run leds-night-mode;

... and back to normal mode:

    /system/script/run leds-day-mode;

To toggle between the two modes:

    /system/script/run leds-toggle-mode;

Add these schedulers to switch to dark mode in the evening and back to
normal mode in the morning:

    /system/scheduler/add interval=1d name=leds-day-mode on-event="/system/script/run leds-day-mode;" start-time=07:00:00;
    /system/scheduler/add interval=1d name=leds-night-mode on-event="/system/script/run leds-night-mode;" start-time=21:00:00;

The script `leds-toggle-mode` can be used from [mode button](mode-button.md)
to toggle mode.

See also
--------

* [Mode button with multiple presses](mode-button.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
