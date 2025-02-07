#!rsc by RouterOS
# RouterOS script: gps-track
# Copyright (c) 2018-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, fetch
#
# track gps data by sending json data to http server
# https://rsc.eworm.de/doc/gps-track.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local ExitOK false;
:do {
  :local ScriptName [ :jobname ];

  :global GpsTrackUrl;
  :global Identity;

  :global FetchUserAgentStr;
  :global LogPrint;
  :global ScriptLock;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }
  $WaitFullyConnected;

  :local CoordinateFormat [ /system/gps/get coordinate-format ];
  :local Gps [ /system/gps/monitor once as-value ];

  :if ($Gps->"valid" = true) do={
    :do {
      /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
        http-header-field=({ [ $FetchUserAgentStr $ScriptName ]; "Content-Type: application/json" }) \
        http-data=[ :serialize to=json { "identity"=$Identity; \
        "lat"=($Gps->"latitude"); "lon"=($Gps->"longitude") } ] $GpsTrackUrl as-value;
      $LogPrint debug $ScriptName ("Sending GPS data in " . $CoordinateFormat . " format: " . \
        "lat: " . ($Gps->"latitude") . " " . \
        "lon: " . ($Gps->"longitude"));
    } on-error={
      $LogPrint warning $ScriptName ("Failed sending GPS data!");
    }
  } else={
    $LogPrint debug $ScriptName ("GPS data not valid.");
  }
} on-error={
  :global ExitError; $ExitError $ExitOK [ :jobname ];
}
