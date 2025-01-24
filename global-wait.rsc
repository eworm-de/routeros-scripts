#!rsc by RouterOS
# RouterOS script: global-wait
# Copyright (c) 2020-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.14
#
# wait for global-functions to finish
# https://rsc.eworm.de/doc/global-wait.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }
