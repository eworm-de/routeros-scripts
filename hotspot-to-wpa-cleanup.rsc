#!rsc by RouterOS
# RouterOS script: hotspot-to-wpa-cleanup
# Copyright (c) 2021-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: lease-script, order=80
#
# manage and clean up private WPA passphrase after hotspot login
# https://git.eworm.de/cgit/routeros-scripts/about/doc/hotspot-to-wpa.md

:local 0 "hotspot-to-wpa-cleanup";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0 false 10;

:local DHCPServers ({});
:foreach Server in=[ /ip/dhcp-server/find where comment~"hotspot-to-wpa" ] do={
  :local ServerVal [ /ip/dhcp-server/get $Server ]
  :if (([ $ParseKeyValueStore ($ServerVal->"comment") ]->"hotspot-to-wpa") = "wpa") do={
    :set ($DHCPServers->($ServerVal->"name")) 1;
  }
}

:foreach Client in=[ /caps-man/registration-table/find where comment~"^hotspot-to-wpa:" ] do={
  :local ClientVal [ /caps-man/registration-table/get $Client ];
  :foreach Lease in=[ /ip/dhcp-server/lease/find where dynamic \
      mac-address=($ClientVal->"mac-address") ] do={
    :if (($DHCPServers->[ /ip/dhcp-server/lease/get $Lease server ]) = 1) do={
      $LogPrintExit2 info $0 ("Client with mac address " . ($ClientVal->"mac-address") . \
        " connected to WPA, making lease static.") false;
      /ip/dhcp-server/lease/make-static $Lease;
      /ip/dhcp-server/lease/set comment=($ClientVal->"comment") $Lease;
    }
  }
}

:foreach Client in=[ /caps-man/access-list/find where comment~"^hotspot-to-wpa:" \
    !(comment~[ /system/clock/get date ]) ] do={
  :local ClientVal [ /caps-man/access-list/get $Client ];
  :if ([ :len [ /ip/dhcp-server/lease/find where !dynamic comment~"^hotspot-to-wpa:" \
       mac-address=($ClientVal->"mac-address") ] ] = 0) do={
    $LogPrintExit2 info $0 ("Client with mac address " . ($ClientVal->"mac-address") . \
      " did not connect to WPA, removing from access list.") false;
    /caps-man/access-list/remove $Client;
  }
}

:foreach Lease in=[ /ip/dhcp-server/lease/find where !dynamic status=waiting \
    last-seen>4w comment~"^hotspot-to-wpa:" ] do={
  :local LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
  $LogPrintExit2 info $0 ("Client with mac address " . ($LeaseVal->"mac-address") . \
    " was not seen for long time, removing.") false;
  /caps-man/access-list/remove [ find where comment~"^hotspot-to-wpa:" \
     mac-address=($LeaseVal->"mac-address") ];
  /ip/dhcp-server/lease/remove $Lease;
}
