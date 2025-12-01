#!rsc by RouterOS
# RouterOS script: accesslist-duplicates%TEMPL%
# Copyright (c) 2018-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# print duplicate antries in wireless access list
# https://rsc.eworm.de/doc/accesslist-duplicates.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :local Seen ({});

  :foreach AccList in=[ /caps-man/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
  :foreach AccList in=[ /interface/wifi/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
  :foreach AccList in=[ /interface/wireless/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
    :local Mac [ /caps-man/access-list/get $AccList mac-address ];
    :local Mac [ /interface/wifi/access-list/get $AccList mac-address ];
    :local Mac [ /interface/wireless/access-list/get $AccList mac-address ];
    :if ($Seen->$Mac = 1) do={
      /caps-man/access-list/print without-paging where mac-address=$Mac;
      /interface/wifi/access-list/print without-paging where mac-address=$Mac;
      /interface/wireless/access-list/print without-paging where mac-address=$Mac;
      :local Remove [ :tonum [ /terminal/ask prompt="\nNumeric id to remove, any key to skip!" ] ];

      :if ([ :typeof $Remove ] = "num") do={
        :put ("Removing numeric id " . $Remove . "...\n");
        /caps-man/access-list/remove $Remove;
        /interface/wifi/access-list/remove $Remove;
        /interface/wireless/access-list/remove $Remove;
      }
    }
    :set ($Seen->$Mac) 1;
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
