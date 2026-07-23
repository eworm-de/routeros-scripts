#!rsc by RouterOS
# RouterOS script: hotspot-to-wpa%TEMPL%
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, hotspot
# requires policy, policy=read;write
#
# add private WPA passphrase after hotspot login
# https://rsc.eworm.de/doc/hotspot-to-wpa.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:onerror Err {
  :local ScriptName [ :jobname ];

  :local Address $"address";
  :local Interface $"interface";
  :local MacAddress $"mac-address";
  :local UserName $"username";

  :local Hotspot [ /ip/hotspot/host/get [ find where mac-address=$MacAddress authorized ] server ];
  :if ([ /caps-man/access-list/find where \
  :if ([ :len [ /interface/wifi/access-list/find where \
       comment=("hotspot-to-wpa template " . $Hotspot) disabled action="reject" ] ] > 0) do={
    :log info ($ScriptName . ": Ignoring login for " . $MacAddress . " on hotspot '" . $Hotspot . "'.");
    :exit;
  }

  :local Lease [ /ip/dhcp-server/lease/find where mac-address=$MacAddress address=$Address ];

  :if ([ :len $Lease ] != 1) do={
    :log warning ($ScriptName . ": Did not find exactly one lease for " . $MacAddress . "!");
    :exit;
  }

  /ip/dhcp-server/lease/set \
    comment=[ :serialize to=json ({ \
      "hotspot-to-wpa"=true; \
      "address"=$Address; \
      "interface"=$Interface; \
      "mac-address"=$MacAddress; \
      "username"=$UserName }) ] $Lease;
  /ip/dhcp-server/lease/make-static $Lease;
  :delay 1s;
  /ip/dhcp-server/lease/disable $Lease;
} do={
  :log error ([ :jobname ] . ": " . $Err);
}
