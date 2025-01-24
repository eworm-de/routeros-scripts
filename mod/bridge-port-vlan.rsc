#!rsc by RouterOS
# RouterOS script: mod/bridge-port-vlan
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.14
#
# manage VLANs on bridge ports
# https://rsc.eworm.de/doc/mod/bridge-port-vlan.md

:global BridgePortVlan;

:global BridgePortVlan do={ :do {
  :local ConfigTo [ :tostr $1 ];

  :global IfThenElse;
  :global LogPrint;
  :global ParseKeyValueStore;

  :local InterfaceReEnable ({});
  :foreach BridgePort in=[ /interface/bridge/port/find where !(comment=[]) ] do={
    :local BridgePortVal [ /interface/bridge/port/get $BridgePort ];
    :foreach Config,Vlan in=[ $ParseKeyValueStore ($BridgePortVal->"comment") ] do={
      :if ($Config = $ConfigTo) do={
        :local DHCPClient [ /ip/dhcp-client/find where interface=$BridgePortVal->"interface" comment="toggle with bridge port" ];

        :if ($Vlan = "dhcp-client") do={
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
          :local VlanName $Vlan;
          :if ($Vlan != [ :tostr [ :tonum $Vlan ] ]) do={
            :do {
              :set $Vlan ([ /interface/bridge/vlan/get [ find where comment=$Vlan ] vlan-ids ]->0);
            } on-error={
              $LogPrint warning $0 ("Could not find VLAN '" . $Vlan . "' for interface " . $BridgePortVal->"interface" . "!");
              :return false;
            }
          }
          :if ($BridgePortVal->"disabled" = true || $Vlan != $BridgePortVal->"pvid") do={
            $LogPrint info $0 ("Enabling bridge port for interface " . $BridgePortVal->"interface" . ", changing to " . $ConfigTo . \
                " vlan " . $Vlan . [ $IfThenElse ($Vlan != $VlanName) (" (" . $VlanName . ")") ] . ", disabling dhcp client.");
            :if ([ :len $DHCPClient ] = 1) do={
              /ip/dhcp-client/disable $DHCPClient;
              :delay 200ms;
            }
            :local Disable [ /interface/ethernet/find where name=$BridgePortVal->"interface" ];
            :if ([ :len $Disable ] > 0) do={
              /interface/ethernet/disable $Disable;
              :set InterfaceReEnable ($InterfaceReEnable, $Disable);
            }
            /interface/bridge/port/set disabled=no pvid=$Vlan $BridgePort;
          } else={
            $LogPrint debug $0 ("Interface " . $BridgePortVal->"interface" . " already connected to " . $ConfigTo . \
                " vlan " . $Vlan . ".");
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
} on-error={
  :global ExitError; $ExitError false $0;
} }
