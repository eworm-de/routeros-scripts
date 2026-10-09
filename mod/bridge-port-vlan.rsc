#!rsc by RouterOS
# RouterOS script: mod/bridge-port-vlan
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# manage VLANs on bridge ports
# https://rsc.eworm.de/doc/mod/bridge-port-vlan.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=bridge-port-vlan, schema=ca51ecefefa0a1bcad40eb3a3ad65db37300e7e3b0f7f3f5abe49a021f6dfda1
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"bridge-port-vlan.client.duplicate") "Duplicate dhcp client configuration for interface {interface}!";
:set ($LanguageEnglish->"bridge-port-vlan.client.enabled") "Disabling bridge port for interface {interface}, enabling dhcp client.";
:set ($LanguageEnglish->"bridge-port-vlan.client.missing") "Missing dhcp client configuration for interface {interface}!";
:set ($LanguageEnglish->"bridge-port-vlan.interfaces.enabled") "Re-enabling interfaces...";
:set ($LanguageEnglish->"bridge-port-vlan.vlan.connected") "Interface {interface} already connected to {config} vlan {vlan}.";
:set ($LanguageEnglish->"bridge-port-vlan.vlan.enabled") "Enabling bridge port for interface {interface}, changing to {config} vlan {vlan}{name}, disabling dhcp client.";
:set ($LanguageEnglish->"bridge-port-vlan.vlan.missing") "Could not find VLAN '{vlan}' for interface {interface}!";
# END GENERATED LANGUAGE DATA

:global BridgePortVlan;

:global BridgePortVlan do={ :onerror Err {
  :local ConfigTo [ :tostr $1 ];

  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;

  :local InterfaceReEnable ({});
  :foreach BridgePort in=[ /interface/bridge/port/find where !(comment=[]) ] do={
    :local BridgePortVal [ /interface/bridge/port/get $BridgePort ];
    :foreach Config,Vlan in=[ $ParseKeyValueStore ($BridgePortVal->"comment") ] do={
      :if ($Config = $ConfigTo) do={
        :local DHCPClient [ /ip/dhcp-client/find where interface=$BridgePortVal->"interface" comment="toggle with bridge port" ];

        :if ($Vlan = "dhcp-client") do={
          :if ([ :len $DHCPClient ] != 1) do={
            :local Diagnostic [ $Translate "bridge-port-vlan.client.duplicate" \
                ({ interface=($BridgePortVal->"interface") }) ];
            :if ([ :len $DHCPClient ] = 0) do={ :set Diagnostic [ $Translate "bridge-port-vlan.client.missing" \
                ({ interface=($BridgePortVal->"interface") }) ]; };
            $LogPrint warning $0 $Diagnostic;
            :return false;
          }
          :local DHCPClientDisabled [ /ip/dhcp-client/get $DHCPClient disabled ];

          :if ($BridgePortVal->"disabled" = false || $DHCPClientDisabled = true) do={
            $LogPrint info $0 [ $Translate "bridge-port-vlan.client.enabled" \
                ({ interface=($BridgePortVal->"interface") }) ];
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
              $LogPrint warning $0 [ $Translate "bridge-port-vlan.vlan.missing" \
                  ({ vlan=$Vlan; interface=($BridgePortVal->"interface") }) ];
              :return false;
            }
          }
          :if ($BridgePortVal->"disabled" = true || $Vlan != $BridgePortVal->"pvid") do={
            $LogPrint info $0 [ $Translate "bridge-port-vlan.vlan.enabled" \
                ({ interface=($BridgePortVal->"interface"); config=$ConfigTo; vlan=$Vlan; name=[ $IfThenElse ($Vlan != $VlanName) (" (" . $VlanName . ")") "" ] }) ];
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
            $LogPrint debug $0 [ $Translate "bridge-port-vlan.vlan.connected" \
                ({ interface=($BridgePortVal->"interface"); config=$ConfigTo; vlan=$Vlan }) ];
          }
        }
      }
    }
  }
  :if ([ :len $InterfaceReEnable ] > 0) do={
    :delay 5s;
    $LogPrint info $0 [ $Translate "bridge-port-vlan.interfaces.enabled" ];
    /interface/ethernet/enable $InterfaceReEnable;
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }
