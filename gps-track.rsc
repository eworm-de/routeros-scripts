#!rsc by RouterOS
# RouterOS script: gps-track
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch
#
# track gps data by sending json data to http server
# https://rsc.eworm.de/doc/gps-track.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=gps-track, schema=8a481e39bc7d2b2c404102ee33d70ef5d9e6f8586410be28a7438746daa9ed83
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"gps-track.failed") "Failed sending GPS data: {error}";
:set ($LanguageEnglish->"gps-track.invalid") "GPS data not valid.";
:set ($LanguageEnglish->"gps-track.sent") "Sending GPS data in {format} format: lat: {latitude} lon: {longitude}";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :global GlobalNotReadyMessage;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error $GlobalNotReadyMessage; }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global GpsTrackUrl;
  :global Identity;

  :global FetchUserAgentStr;
  :global LogPrint;
  :global Translate;
  :global ScriptLock;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
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
      $LogPrint debug $ScriptName [ $Translate "gps-track.sent" ({ format=$CoordinateFormat; latitude=($Gps->"latitude"); longitude=($Gps->"longitude") }) ];
    } do={
      $LogPrint warning $ScriptName [ $Translate "gps-track.failed" ({ error=$Err }) ];
    }
  } else={
    $LogPrint debug $ScriptName [ $Translate "gps-track.invalid" ];
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
