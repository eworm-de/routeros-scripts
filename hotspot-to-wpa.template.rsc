#!rsc by RouterOS
# RouterOS script: hotspot-to-wpa%TEMPL%
# Copyright (c) 2019-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.12
#
# add private WPA passphrase after hotspot login
# https://git.eworm.de/cgit/routeros-scripts/about/doc/hotspot-to-wpa.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local Main do={
  :local ScriptName [ :tostr $1 ];
  :local MacAddress [ :tostr $2 ];
  :local UserName   [ :tostr $3 ];

  :global EitherOr;
  :global LogPrintExit2;
  :global ParseKeyValueStore;
  :global ScriptLock;

  $ScriptLock $ScriptName;

  :if ([ :len $MacAddress ] = 0 || [ :len $UserName ] = 0) do={
    $LogPrintExit2 error $ScriptName ("This script is supposed to run from hotspot on login.") true;
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
  :if ([ :len [ /interface/wifiwave2/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ] ] = 0) do={
    /caps-man/access-list/add comment="--- hotspot-to-wpa above ---" disabled=yes;
    /interface/wifi/access-list/add comment="--- hotspot-to-wpa above ---" disabled=yes;
    /interface/wifiwave2/access-list/add comment="--- hotspot-to-wpa above ---" disabled=yes;
    $LogPrintExit2 warning $ScriptName ("Added disabled access-list entry with comment '--- hotspot-to-wpa above ---'.") false;
  }
  :local PlaceBefore ([ /caps-man/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ]->0);
  :local PlaceBefore ([ /interface/wifi/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ]->0);
  :local PlaceBefore ([ /interface/wifiwave2/access-list/find where comment="--- hotspot-to-wpa above ---" disabled ]->0);

  :if ([ :len [ /caps-man/access-list/find where \
  :if ([ :len [ /interface/wifi/access-list/find where \
  :if ([ :len [ /interface/wifiwave2/access-list/find where \
      comment=("hotspot-to-wpa template " . $Hotspot) disabled ] ] = 0) do={
    /caps-man/access-list/add comment=("hotspot-to-wpa template " . $Hotspot) disabled=yes place-before=$PlaceBefore;
    /interface/wifi/access-list/add comment=("hotspot-to-wpa template " . $Hotspot) disabled=yes place-before=$PlaceBefore;
    /interface/wifiwave2/access-list/add comment=("hotspot-to-wpa template " . $Hotspot) disabled=yes place-before=$PlaceBefore;
    $LogPrintExit2 warning $ScriptName ("Added template in access-list for hotspot '" . $Hotspot . "'.") false;
  }
  :local Template [ /caps-man/access-list/get ([ find where \
  :local Template [ /interface/wifi/access-list/get ([ find where \
  :local Template [ /interface/wifiwave2/access-list/get ([ find where \
      comment=("hotspot-to-wpa template " . $Hotspot) disabled ]->0) ];

  :if ($Template->"action" = "reject") do={
    $LogPrintExit2 info $ScriptName ("Ignoring login for hotspot '" . $Hotspot . "'.") false;
    :return true;
  }

  # allow login page to load
  :delay 1s;

  $LogPrintExit2 info $ScriptName ("Adding/updating access-list entry for mac address " . $MacAddress . \
    " (user " . $UserName . ").") false;
  /caps-man/access-list/remove [ find where mac-address=$MacAddress comment~"^hotspot-to-wpa: " ];
  /interface/wifi/access-list/remove [ find where mac-address=$MacAddress comment~"^hotspot-to-wpa: " ];
  /interface/wifiwave2/access-list/remove [ find where mac-address=$MacAddress comment~"^hotspot-to-wpa: " ];
  /caps-man/access-list/add private-passphrase=($UserVal->"password") ssid-regexp="-wpa\$" \
  /interface/wifi/access-list/add passphrase=($UserVal->"password") ssid-regexp="-wpa\$" \
  /interface/wifiwave2/access-list/add passphrase=($UserVal->"password") ssid-regexp="-wpa\$" \
      mac-address=$MacAddress comment=("hotspot-to-wpa: " . $UserName . ", " . $MacAddress . ", " . $Date) \
      action=reject place-before=$PlaceBefore;

  :local Entry [ /caps-man/access-list/find where mac-address=$MacAddress \
  :local Entry [ /interface/wifi/access-list/find where mac-address=$MacAddress \
  :local Entry [ /interface/wifiwave2/access-list/find where mac-address=$MacAddress \
      comment=("hotspot-to-wpa: " . $UserName . ", " . $MacAddress . ", " . $Date) ];
# NOT /caps-man/ #
  :set ($Template->"private-passphrase") ($Template->"passphrase");
# NOT /caps-man/ #
  :local PrivatePassphrase [ $EitherOr ($UserInfo->"private-passphrase") ($Template->"private-passphrase") ];
  :if ([ :len $PrivatePassphrase ] > 0) do={
    :if ($PrivatePassphrase = "ignore") do={
      /caps-man/access-list/set $Entry !private-passphrase;
      /interface/wifi/access-list/set $Entry !passphrase;
      /interface/wifiwave2/access-list/set $Entry !passphrase;
    } else={
      /caps-man/access-list/set $Entry private-passphrase=$PrivatePassphrase;
      /interface/wifi/access-list/set $Entry passphrase=$PrivatePassphrase;
      /interface/wifiwave2/access-list/set $Entry passphrase=$PrivatePassphrase;
    }
  }
  :local SsidRegexp [ $EitherOr ($UserInfo->"ssid-regexp") ($Template->"ssid-regexp") ];
  :if ([ :len $SsidRegexp ] > 0) do={
    /caps-man/access-list/set $Entry ssid-regexp=$SsidRegexp;
    /interface/wifi/access-list/set $Entry ssid-regexp=$SsidRegexp;
    /interface/wifiwave2/access-list/set $Entry ssid-regexp=$SsidRegexp;
  }
  :local VlanId [ $EitherOr ($UserInfo->"vlan-id") ($Template->"vlan-id") ];
  :if ([ :len $VlanId ] > 0) do={
    /caps-man/access-list/set $Entry vlan-id=$VlanId;
    /interface/wifi/access-list/set $Entry vlan-id=$VlanId;
    /interface/wifiwave2/access-list/set $Entry vlan-id=$VlanId;
  }
# NOT /interface/wifi/ #
# NOT /interface/wifiwave2/ #
  :local VlanMode [ $EitherOr ($UserInfo->"vlan-mode") ($Template->"vlan-mode") ];
  :if ([ :len $VlanMode] > 0) do={
    /caps-man/access-list/set $Entry vlan-mode=$VlanMode;
  }
# NOT /interface/wifiwave2/ #
# NOT /interface/wifi/ #

  :delay 2s;
  /caps-man/access-list/set $Entry action=accept;
  /interface/wifi/access-list/set $Entry action=accept;
  /interface/wifiwave2/access-list/set $Entry action=accept;
}

$Main [ :jobname ] $"mac-address" $username;
