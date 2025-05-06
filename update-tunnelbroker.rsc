#!rsc by RouterOS
# RouterOS script: update-tunnelbroker
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: ppp-on-up
# requires RouterOS, version=7.15
# requires device-mode, fetch
#
# update local address of tunnelbroker interface
# https://rsc.eworm.de/doc/update-tunnelbroker.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global CertificateAvailable;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :if ([ $CertificateAvailable "Starfield Root Certificate Authority - G2" ] = false) do={
    $LogPrint error $ScriptName ("Downloading required certificate failed.");
    :set ExitOK true;
    :error false;
  }

  :foreach Interface in=[ /interface/6to4/find where comment~"^tunnelbroker" !disabled ] do={
    :local Data false;
    :local InterfaceVal [ /interface/6to4/get $Interface ];
    :local Comment [ $ParseKeyValueStore ($InterfaceVal->"comment") ];

    :for I from=2 to=0 do={
      :if ($Data = false) do={
        :do {
          :set Data ([ /tool/fetch check-certificate=yes-without-crl \
            ("https://ipv4.tunnelbroker.net/nic/update?hostname=" . $Comment->"id") \
            user=($Comment->"user") password=($Comment->"pass") output=user as-value ]->"data");
        } on-error={
          $LogPrint debug $ScriptName ("Failed downloading, " . $I . " retries pending.");
          :delay 2s;
        }
      }
    }

    :if (!($Data ~ "^(good|nochg) ")) do={
      $LogPrint error $ScriptName ("Failed sending the local address to tunnelbroker or unexpected response!");
      :set ExitOK true;
      :error false;
    }

    :local PublicAddress [ :pick $Data ([ :find $Data " " ] + 1) [ :find $Data "\n" ] ];

    :if ($PublicAddress != $InterfaceVal->"local-address") do={
      :if ([ :len [ /ip/address find where address~("^" . $PublicAddress . "/") ] ] < 1) do={
        $LogPrint warning $ScriptName ("The address " . $PublicAddress . " is not configured on your device. NAT by ISP?");
      }

      $LogPrint info $ScriptName ("Local address changed, updating tunnel configuration with address: " . $PublicAddress);
      /interface/6to4/set $Interface local-address=$PublicAddress;
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
