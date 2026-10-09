#!rsc by RouterOS
# RouterOS script: mod/bridge-port-to
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# reset bridge ports to default bridge
# https://rsc.eworm.de/doc/mod/bridge-port-to.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=bridge-port-to, schema=9ff4cd55d43b5e48046edec247245c26cd52574d351dd5b3d5c66b36824548d6
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"bridge-port-to.bridge.connected") "Interface {interface} already connected to {config} bridge {bridge}.";
:set ($LanguageEnglish->"bridge-port-to.bridge.enabled") "Enabling bridge port for interface {interface}, changing to {config} bridge {bridge}, disabling dhcp client.";
:set ($LanguageEnglish->"bridge-port-to.client.duplicate") "Duplicate dhcp client configuration for interface {interface}!";
:set ($LanguageEnglish->"bridge-port-to.client.enabled") "Disabling bridge port for interface {interface}, enabling dhcp client.";
:set ($LanguageEnglish->"bridge-port-to.client.missing") "Missing dhcp client configuration for interface {interface}!";
:set ($LanguageEnglish->"bridge-port-to.interfaces.enabled") "Re-enabling interfaces...";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:global BridgePortTo;

:set BridgePortTo do={ :onerror Err {
  :local BridgePortTo [ :tostr $1 ];

  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;

  :local InterfaceReEnable ({});
  :foreach BridgePort in=[ /interface/bridge/port/find where !(comment=[]) ] do={
    :local BridgePortVal [ /interface/bridge/port/get $BridgePort ];
    :foreach Config,BridgeDefault in=[ $ParseKeyValueStore ($BridgePortVal->"comment") ] do={
      :if ($Config = $BridgePortTo) do={
        :local DHCPClient [ /ip/dhcp-client/find where interface=$BridgePortVal->"interface" comment="toggle with bridge port" ];

        :if ($BridgeDefault = "dhcp-client") do={
          :if ([ :len $DHCPClient ] != 1) do={
            :local Diagnostic [ $Translate "bridge-port-to.client.duplicate" \
                ({ interface=($BridgePortVal->"interface") }) ];
            :if ([ :len $DHCPClient ] = 0) do={ :set Diagnostic [ $Translate "bridge-port-to.client.missing" \
                ({ interface=($BridgePortVal->"interface") }) ]; };
            $LogPrint warning $0 $Diagnostic;
            :return false;
          }
          :local DHCPClientDisabled [ /ip/dhcp-client/get $DHCPClient disabled ];

          :if ($BridgePortVal->"disabled" = false || $DHCPClientDisabled = true) do={
            $LogPrint info $0 [ $Translate "bridge-port-to.client.enabled" \
                ({ interface=($BridgePortVal->"interface") }) ];
            /interface/bridge/port/disable $BridgePort;
            :delay 200ms;
            /ip/dhcp-client/enable $DHCPClient;
          }
        } else={
          :if ($BridgePortVal->"disabled" = true || $BridgeDefault != $BridgePortVal->"bridge") do={
            $LogPrint info $0 [ $Translate "bridge-port-to.bridge.enabled" \
                ({ interface=($BridgePortVal->"interface"); config=$BridgePortTo; bridge=$BridgeDefault }) ];
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
            $LogPrint debug $0 [ $Translate "bridge-port-to.bridge.connected" \
                ({ interface=($BridgePortVal->"interface"); config=$BridgePortTo; bridge=$BridgeDefault }) ];
          }
        }
      }
    }
  }
  :if ([ :len $InterfaceReEnable ] > 0) do={
    :delay 5s;
    $LogPrint info $0 [ $Translate "bridge-port-to.interfaces.enabled" ];
    /interface/ethernet/enable $InterfaceReEnable;
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }
