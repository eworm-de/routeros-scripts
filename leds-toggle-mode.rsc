#!rsc by RouterOS
# RouterOS script: leds-toggle-mode
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# toggle LEDs mode
# https://rsc.eworm.de/doc/leds-mode.md

/system/leds/settings/set all-leds-off=(({ "never"="immediate"; "immediate"="never" })->[ get all-leds-off ]);
