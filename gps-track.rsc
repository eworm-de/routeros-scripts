#!rsc by RouterOS
# Skrip RouterOS: gps-track
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, fetch
#
# track gps data by sending json data to http server
# https://rsc.eworm.de/doc/gps-track.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
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
    :onerror Err {
      /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
        http-header-field=({ [ $FetchUserAgentStr $ScriptName ]; "Content-Type: application/json" }) \
        http-data=[ :serialize to=json { "identity"=$Identity; \
        "lat"=($Gps->"latitude"); "lon"=($Gps->"longitude") } ] $GpsTrackUrl as-value;
      $LogPrint debug $ScriptName ("Sending GPS data in " . $CoordinateFormat . " format: " . \
        "lat: " . ($Gps->"latitude") . " " . \
        "lon: " . ($Gps->"longitude"));
    } do={
      $LogPrint warning $ScriptName ("Failed sending GPS data: " . $Err);
    }
  } else={
    $LogPrint debug $ScriptName ("GPS data not valid.");
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
