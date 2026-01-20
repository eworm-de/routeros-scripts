#!rsc by RouterOS
# RouterOS script: mod/bridge-port-to
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.17
#
# reset bridge ports to default bridge
# https://rsc.eworm.de/doc/mod/bridge-port-to.md

:global BridgePortTo;

:set BridgePortTo do={ :onerror Err {
  :local BridgePortTo [ :tostr $1 ];

  :global IfThenElse;
  :global LogPrint;
  :global ParseKeyValueStore;

  :local InterfaceReEnable ({});
  :foreach BridgePort in=[ /interface/bridge/port/find where !(comment=[]) ] do={
    :local BridgePortVal [ /interface/bridge/port/get $BridgePort ];
    :foreach Config,BridgeDefault in=[ $ParseKeyValueStore ($BridgePortVal->"comment") ] do={
      :if ($Config = $BridgePortTo) do={
        :local DHCPClient [ /ip/dhcp-client/find where interface=$BridgePortVal->"interface" comment="toggle with bridge port" ];

        :if ($BridgeDefault = "dhcp-client") do={
          :if ([ :len $DHCPClient ] != 1) do={
            $LogPrint warning $0 ([ $IfThenElse ([ :len $DHCPClient ] = 0) "Missing" "Duplicate" ] . \
                " dhcp client configuration for interface " . $BridgePortVal->"interface" . "!");
            :return false;
          }
          :local DHCPClientDisabled [ /ip/dhcp-client/get $DHCPClient disabled ];

          :if ($BridgePortVal->"disabled" = false || $DHCPClientDisabled = true) do={
            $LogPrint info $0 ("Disabling bridge port for interface " . $BridgePortVal->"interface" . ", enabling dhcp client.");
            /interface/bridge/port/disable $BridgePort;
            :delay 200ms;
            /ip/dhcp-client/enable $DHCPClient;
          }
        } else={
          :if ($BridgePortVal->"disabled" = true || $BridgeDefault != $BridgePortVal->"bridge") do={
            $LogPrint info $0 ("Enabling bridge port for interface " . $BridgePortVal->"interface" . ", changing to " . $BridgePortTo . \
                " bridge " . $BridgeDefault . ", disabling dhcp client.");
            :if ([ :len $DHCPClient ] = 1) do={
              /ip/dhcp-client/disable $DHCPClient;
              :delay 200ms;
            }
            :local Disable [ /interface/ethernet/find where name=$BridgePortVal->"interface" ];
            :if ([ :len $Disable ] > 0) do={
              /interface/ethernet/disable $Disable;
              :set InterfaceReEnable ($InterfaceReEnable, $Disable);
            }
            /interface/bridge/port/set disabled=no bridge=$BridgeDefault $BridgePort;
          } else={
            $LogPrint debug $0 ("Interface " . $BridgePortVal->"interface" . " already connected to " . $BridgePortTo . \
                " bridge " . $BridgeDefault . ".");
          }
        }
      }
    }
  }
  :if ([ :len $InterfaceReEnable ] > 0) do={
    :delay 5s;
    $LogPrint info $0 ("Re-enabling interfaces...");
    /interface/ethernet/enable $InterfaceReEnable;
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }
