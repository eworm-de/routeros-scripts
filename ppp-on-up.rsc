#!rsc by RouterOS
# RouterOS script: ppp-on-up
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# run scripts on ppp up
# https://rsc.eworm.de/doc/ppp-on-up.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global LogPrint;

  :local Interface $interface;

  :if ([ :typeof $Interface ] = "nothing") do={
    $LogPrint error $ScriptName ("This script is supposed to run from ppp on-up script hook.");
    :set ExitOK true;
    :error false;
  }

  :local IntName [ /interface/get $Interface name ];
  $LogPrint info $ScriptName ("PPP interface " . $IntName . " is up.");

  /ipv6/dhcp-client/release [ find where interface=$IntName !disabled bound ];

  :foreach Script in=[ /system/script/find where source~("\n# provides: ppp-on-up\r?\n") ] do={
    :local ScriptName [ /system/script/get $Script name ];
    :do {
      $LogPrint debug $ScriptName ("Running script: " . $ScriptName);
      /system/script/run $Script;
    } on-error={
      $LogPrint warning $ScriptName ("Running script '" . $ScriptName . "' failed!");
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
