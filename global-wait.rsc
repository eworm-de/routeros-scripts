#!rsc by RouterOS
# RouterOS script: global-wait
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# wait for global-functions to finish
# https://rsc.eworm.de/doc/global-wait.md

:global GlobalConfigReady;
:global GlobalFunctionsReady;
:while ($GlobalConfigReady != true || $GlobalFunctionsReady != true) do={ :delay 500ms; }
