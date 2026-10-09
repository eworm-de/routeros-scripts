#!rsc by RouterOS
# RouterOS script: update-tunnelbroker
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: ppp-on-up
# requires RouterOS, version=7.22
# requires device-mode, fetch
#
# update local address of tunnelbroker interface
# https://rsc.eworm.de/doc/update-tunnelbroker.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=update-tunnelbroker, schema=a1b3554a6dc3737e590e438648393e5c28b297b740eb02023c141abd6fe84d4e
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"update-tunnelbroker.address.missing") "The address {address} is not configured on your device. NAT by ISP?";
:set ($LanguageEnglish->"update-tunnelbroker.certificate.failed") "Downloading required certificate failed.";
:set ($LanguageEnglish->"update-tunnelbroker.download.failed") "Failed downloading: {error} - {count} retries pending.";
:set ($LanguageEnglish->"update-tunnelbroker.response.invalid") "Failed sending the local address to tunnelbroker or unexpected response!";
:set ($LanguageEnglish->"update-tunnelbroker.updating") "Local address changed, updating tunnel configuration with address: {address}";
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global CertificateAvailable;
  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :if ([ $CertificateAvailable "Starfield Root Certificate Authority - G2" "fetch" ] = false) do={
    $LogPrint error $ScriptName [ $Translate "update-tunnelbroker.certificate.failed" ];
    :exit;
  }

  :foreach Interface in=[ /interface/6to4/find where comment~"^tunnelbroker" !disabled ] do={
    :local Data false;
    :local InterfaceVal [ /interface/6to4/get $Interface ];
    :local Comment [ $ParseKeyValueStore ($InterfaceVal->"comment") ];

    :for I from=2 to=0 do={
      :if ($Data = false) do={
        :onerror Err {
          :set Data ([ /tool/fetch check-certificate=yes-without-crl \
            ("https://ipv4.tunnelbroker.net/nic/update?hostname=" . $Comment->"id") \
            user=($Comment->"user") password=($Comment->"pass") output=user as-value ]->"data");
        } do={
          $LogPrint debug $ScriptName [ $Translate "update-tunnelbroker.download.failed" \
              ({ error=$Err; count=$I }) ];
          :delay 2s;
        }
      }
    }

    :if (!($Data ~ "^(good|nochg) ")) do={
      $LogPrint error $ScriptName [ $Translate "update-tunnelbroker.response.invalid" ];
      :exit;
    }

    :local PublicAddress [ :pick $Data ([ :find $Data " " ] + 1) [ :find $Data "\n" ] ];

    :if ($PublicAddress != $InterfaceVal->"local-address") do={
      :if ([ :len [ /ip/address find where address~("^" . $PublicAddress . "/") ] ] < 1) do={
        $LogPrint warning $ScriptName [ $Translate "update-tunnelbroker.address.missing" \
            ({ address=$PublicAddress }) ];
      }

      $LogPrint info $ScriptName [ $Translate "update-tunnelbroker.updating" \
          ({ address=$PublicAddress }) ];
      /interface/6to4/set $Interface local-address=$PublicAddress;
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
