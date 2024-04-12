#!rsc by RouterOS
# RouterOS script: gps-track
# Copyright (c) 2018-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.13
#
# track gps data by sending json data to http server
# https://git.eworm.de/cgit/routeros-scripts/about/doc/gps-track.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global GpsTrackUrl;
  :global Identity;

  :global LogPrint;
  :global ScriptLock;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :error false;
  }
  $WaitFullyConnected;

  :local CoordinateFormat [ /system/gps/get coordinate-format ];
  :local Gps [ /system/gps/monitor once as-value ];

  :if ($Gps->"valid" = true) do={
    :do {
      /tool/fetch check-certificate=yes-without-crl $GpsTrackUrl output=none \
        http-method=post http-header-field=({ "Content-Type: application/json" }) \
        http-data=[ :serialize to=json { "identity"=$Identity; \
        "lat"=($Gps->"latitude"); "lon"=($Gps->"longitude") } ] as-value;
      $LogPrint debug $ScriptName ("Sending GPS data in " . $CoordinateFormat . " format: " . \
        "lat: " . ($Gps->"latitude") . " " . \
        "lon: " . ($Gps->"longitude"));
    } on-error={
      $LogPrint warning $ScriptName ("Failed sending GPS data!");
    }
  } else={
    $LogPrint debug $ScriptName ("GPS data not valid.");
  }
} on-error={ }
