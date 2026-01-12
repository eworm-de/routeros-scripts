#!rsc by RouterOS
# RouterOS script: hotspot-to-wpa%TEMPL%
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.17
# requires device-mode, hotspot
#
# add private WPA passphrase after hotspot login
# https://rsc.eworm.de/doc/hotspot-to-wpa.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global EitherOr;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :local MacAddress $"mac-address";
  :local UserName $username;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :if ([ :typeof $MacAddress ] = "nothing" || [ :typeof $UserName ] = "nothing") do={
    $LogPrint error $ScriptName ("This script is supposed to run from hotspot on login.");
    :set ExitOK true;
    :error false;
  }

  :local Date [ /system/clock/get date ];
  :local UserVal ({});
  :if ([ :len [ /ip/hotspot/user/find where name=$UserName ] ] > 0) do={
    :set UserVal [ /ip/hotspot/user/get [ find where name=$UserName ] ];
  }
  :local UserInfo [ $ParseKeyValueStore ($UserVal->"comment") ];
  :local Hotspot [ /ip/hotspot/host/get [ find where mac-address=$MacAddress authorized ] server ];

  :if ([ :len [ /caps-man/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ] ] = 0) do={
  :if ([ :len [ /interface/wifi/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ] ] = 0) do={
    /caps-man/access-list/add comment="--- hotspot-to-wpa above ---" disabled=yes;
    /interface/wifi/access-list/add comment="--- hotspot-to-wpa above ---" disabled=yes;
    $LogPrint warning $ScriptName ("Added disabled access-list entry with comment '--- hotspot-to-wpa above ---'.");
  }
  :local PlaceBefore ([ /caps-man/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ]->0);
  :local PlaceBefore ([ /interface/wifi/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ]->0);

  :if ([ :len [ /caps-man/access-list/find where \
  :if ([ :len [ /interface/wifi/access-list/find where \
      comment=("hotspot-to-wpa template " . $Hotspot) disabled ] ] = 0) do={
    /caps-man/access-list/add comment=("hotspot-to-wpa template " . $Hotspot) disabled=yes place-before=$PlaceBefore;
    /interface/wifi/access-list/add comment=("hotspot-to-wpa template " . $Hotspot) disabled=yes place-before=$PlaceBefore;
    $LogPrint warning $ScriptName ("Added template in access-list for hotspot '" . $Hotspot . "'.");
  }
  :local Template [ /caps-man/access-list/get ([ find where \
  :local Template [ /interface/wifi/access-list/get ([ find where \
      comment=("hotspot-to-wpa template " . $Hotspot) disabled ]->0) ];

  :if ($Template->"action" = "reject") do={
    $LogPrint info $ScriptName ("Ignoring login for hotspot '" . $Hotspot . "'.");
    :set ExitOK true;
    :error true;
  }

  # allow login page to load
  :delay 1s;

  $LogPrint info $ScriptName ("Adding/updating access-list entry for mac address " . $MacAddress . \
    " (user " . $UserName . ").");
  /caps-man/access-list/remove [ find where mac-address=$MacAddress comment~"^hotspot-to-wpa: " ];
  /interface/wifi/access-list/remove [ find where mac-address=$MacAddress comment~"^hotspot-to-wpa: " ];
  /caps-man/access-list/add private-passphrase=($UserVal->"password") ssid-regexp="-wpa\$" \
  /interface/wifi/access-list/add passphrase=($UserVal->"password") ssid-regexp="-wpa\$" \
      mac-address=$MacAddress comment=("hotspot-to-wpa: " . $UserName . ", " . $MacAddress . ", " . $Date) \
      action=reject place-before=$PlaceBefore;

  :local Entry [ /caps-man/access-list/find where mac-address=$MacAddress \
  :local Entry [ /interface/wifi/access-list/find where mac-address=$MacAddress \
      comment=("hotspot-to-wpa: " . $UserName . ", " . $MacAddress . ", " . $Date) ];
# NOT /caps-man/ #
  :set ($Template->"private-passphrase") ($Template->"passphrase");
# NOT /caps-man/ #
  :local PrivatePassphrase [ $EitherOr ($UserInfo->"private-passphrase") ($Template->"private-passphrase") ];
  :if ([ :len $PrivatePassphrase ] > 0) do={
    :if ($PrivatePassphrase = "ignore") do={
      /caps-man/access-list/set $Entry !private-passphrase;
      /interface/wifi/access-list/set $Entry !passphrase;
    } else={
      /caps-man/access-list/set $Entry private-passphrase=$PrivatePassphrase;
      /interface/wifi/access-list/set $Entry passphrase=$PrivatePassphrase;
    }
  }
  :local SsidRegexp [ $EitherOr ($UserInfo->"ssid-regexp") ($Template->"ssid-regexp") ];
  :if ([ :len $SsidRegexp ] > 0) do={
    /caps-man/access-list/set $Entry ssid-regexp=$SsidRegexp;
    /interface/wifi/access-list/set $Entry ssid-regexp=$SsidRegexp;
  }
  :local VlanId [ $EitherOr ($UserInfo->"vlan-id") ($Template->"vlan-id") ];
  :if ([ :len $VlanId ] > 0) do={
    /caps-man/access-list/set $Entry vlan-id=$VlanId;
    /interface/wifi/access-list/set $Entry vlan-id=$VlanId;
  }
# NOT /interface/wifi/ #
  :local VlanMode [ $EitherOr ($UserInfo->"vlan-mode") ($Template->"vlan-mode") ];
  :if ([ :len $VlanMode] > 0) do={
    /caps-man/access-list/set $Entry vlan-mode=$VlanMode;
  }
# NOT /interface/wifi/ #

  :delay 2s;
  /caps-man/access-list/set $Entry action=accept;
  /interface/wifi/access-list/set $Entry action=accept;
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
