#!rsc by RouterOS
# RouterOS script: ppp-on-up
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# run scripts on ppp up
# https://rsc.eworm.de/doc/ppp-on-up.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=ppp-on-up, schema=948ef5fc1bb267e734267f57a5d70df419d106197075fec109f206534ce4493c
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"ppp-on-up.context.invalid") "This script is supposed to run from ppp on-up script hook.";
:set ($LanguageEnglish->"ppp-on-up.script.failed") "Running script '{name}' failed!";
:set ($LanguageEnglish->"ppp-on-up.script.running") "Running script: {name}";
:set ($LanguageEnglish->"ppp-on-up.up") "PPP interface {interface} is up.";
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global LogPrint;
  :global Translate;

  :local Interface $interface;

  :if ([ :typeof $Interface ] = "nothing") do={
    $LogPrint error $ScriptName [ $Translate "ppp-on-up.context.invalid" ];
    :exit;
  }

  :local IntName [ /interface/get $Interface name ];
  $LogPrint info $ScriptName [ $Translate "ppp-on-up.up" \
      ({ interface=$IntName }) ];

  /ipv6/dhcp-client/release [ find where interface=$IntName !disabled bound ];

  :foreach Script in=[ /system/script/find where source~("\n# provides: ppp-on-up\r?\n") ] do={
    :local ScriptName [ /system/script/get $Script name ];
    :do {
      $LogPrint debug $ScriptName [ $Translate "ppp-on-up.script.running" \
          ({ name=$ScriptName }) ];
      /system/script/run $Script;
    } on-error={
      $LogPrint warning $ScriptName [ $Translate "ppp-on-up.script.failed" \
          ({ name=$ScriptName }) ];
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
