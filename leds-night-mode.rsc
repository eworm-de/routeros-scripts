#!rsc by RouterOS
# Skrip RouterOS: leds-night-mode
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# disable LEDs
# https://rsc.eworm.de/doc/leds-mode.md

/system/leds/settings/set all-leds-off=immediate;
