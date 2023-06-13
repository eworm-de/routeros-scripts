#!rsc by RouterOS
# RouterOS script: update-tunnelbroker
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: ppp-on-up
#
# update local address of tunnelbroker interface
# https://git.eworm.de/cgit/routeros-scripts/about/doc/update-tunnelbroker.md

:local 0 "update-tunnelbroker";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global CertificateAvailable;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0;

:if ([ $CertificateAvailable "Starfield Secure Certificate Authority - G2" ] = false) do={
  $LogPrintExit2 error $0 ("Downloading required certificate failed.") true;
}

:foreach Interface in=[ /interface/6to4/find where comment~"^tunnelbroker" !disabled ] do={
  :local I 0;
  :local Response "";
  :local InterfaceVal [ /interface/6to4/get $Interface ];
  :local Comment [ $ParseKeyValueStore ($InterfaceVal->"comment") ];

  :while ($I < 3 && $Response = "") do={
    :do {
      :set Response ([ /tool/fetch check-certificate=yes-without-crl \
          ("https://ipv4.tunnelbroker.net/nic/update\?hostname=" . $Comment->"id") \
          user=($Comment->"user") password=($Comment->"pass") output=user as-value ]->"data");
    } on-error={
      :delay 10s;
      :set I ($I + 1);
    }
  }

  :if (!($Response~"^(good|nochg) ")) do={
    $LogPrintExit2 error $0 ("Failed sending the local address to tunnelbroker or unexpected response!") true;
  }

  :local PublicAddress [ :pick $Response ([ :find $Response " " ] + 1) [ :find $Response "\n" ] ];

  :if ($PublicAddress != $InterfaceVal->"local-address") do={
    :if ([ :len [ /ip/address find where address~("^" . $PublicAddress . "/") ] ] < 1) do={
      $LogPrintExit2 warning $0 ("The address " . $PublicAddress . " is not configured on your device. NAT by ISP?") false;
    }

    $LogPrintExit2 info $0 ("Local address changed, updating tunnel configuration with address: " . $PublicAddress) false;
    /interface/6to4/set $Interface local-address=$PublicAddress;
  }
}
