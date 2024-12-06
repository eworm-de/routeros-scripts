#!rsc by RouterOS
# RouterOS script: accesslist-duplicates%TEMPL%
# Copyright (c) 2018-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.14
#
# print duplicate antries in wireless access list
# https://git.eworm.de/cgit/routeros-scripts/about/doc/accesslist-duplicates.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local ExitOK false;
:do {
  :local ScriptName [ :jobname ];

  :local Seen ({});

  :foreach AccList in=[ /caps-man/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
  :foreach AccList in=[ /interface/wifi/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
  :foreach AccList in=[ /interface/wireless/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
    :local Mac [ /caps-man/access-list/get $AccList mac-address ];
    :local Mac [ /interface/wifi/access-list/get $AccList mac-address ];
    :local Mac [ /interface/wireless/access-list/get $AccList mac-address ];
    :if ($Seen->$Mac = 1) do={
      /caps-man/access-list/print where mac-address=$Mac;
      /interface/wifi/access-list/print where mac-address=$Mac;
      /interface/wireless/access-list/print where mac-address=$Mac;
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
} on-error={
  :global ExitError; $ExitError $ExitOK [ :jobname ];
}
