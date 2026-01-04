#!rsc by RouterOS
# Skrip RouterOS: ip-addr-bridge
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# enable or disable ip addresses based on bridge port state
# https://rsc.eworm.de/doc/ip-addr-bridge.md

:foreach Bridge in=[ /interface/bridge/find ] do={
  :local BrName [ /interface/bridge/get $Bridge name ];
  :if ([ :len [ /interface/bridge/port/find where bridge=$BrName ] ] > 0) do={
    :if ([ :len [ /interface/bridge/port/find where bridge=$BrName and inactive=no ] ] = 0) do={
      /ip/address/disable [ find where !dynamic interface=$BrName ];
    } else={
      /ip/address/enable [ find where !dynamic interface=$BrName ];
    }
  }
}
