#!rsc by RouterOS
# RouterOS script: leds-toggle-mode
# Copyright (c) 2018-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# toggle LEDs mode
# https://git.eworm.de/cgit/routeros-scripts/about/doc/leds-mode.md

:if ([ /system/leds/settings/get all-leds-off ] = "never") do={
  /system/leds/settings/set all-leds-off=immediate;
} else={
  /system/leds/settings/set all-leds-off=never;
}
