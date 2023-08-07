#!rsc by RouterOS
# RouterOS script: accesslist-duplicates%TEMPL%
# Copyright (c) 2018-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# print duplicate antries in wireless access list
# https://git.eworm.de/cgit/routeros-scripts/about/doc/accesslist-duplicates.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:local 0 "accesslist-duplicates%TEMPL%";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global Read;

:local Seen ({});
:local Shown ({});

:foreach AccList in=[ /caps-man/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
:foreach AccList in=[ /interface/wireless/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
  :local Mac [ /caps-man/access-list/get $AccList mac-address ];
  :local Mac [ /interface/wireless/access-list/get $AccList mac-address ];
  :foreach SeenMac in=$Seen do={
    :if ($SeenMac = $Mac) do={
      :local Skip 0;
      :foreach ShownMac in=$Shown do={
        :if ($ShownMac = $Mac) do={ :set Skip 1; }
      }
      :if ($Skip = 0) do={
        /caps-man/access-list/print where mac-address=$Mac;
        /interface/wireless/access-list/print where mac-address=$Mac;
        :set Shown ($Shown, $Mac);

        :put "\nNumeric id to remove, any key to skip!";
        :local Remove [ :tonum [ $Read ] ];
        :if ([ :typeof $Remove ] = "num") do={
          :put ("Removing numeric id " . $Remove . "...\n");
          /caps-man/access-list/remove $Remove;
          /interface/wireless/access-list/remove $Remove;
        }
      }
    }
  }
  :set Seen ($Seen, $Mac);
}
