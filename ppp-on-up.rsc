#!rsc by RouterOS
# RouterOS script: ppp-on-up
# Copyright (c) 2013-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.12
#
# run scripts on ppp up
# https://git.eworm.de/cgit/routeros-scripts/about/doc/ppp-on-up.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local Main do={
  :local ScriptName [ :tostr $1 ];
  :local Interface           $2;

  :global LogPrintExit2;

  :if ([ :typeof $Interface ] = "nothing") do={
    $LogPrintExit2 error $ScriptName ("This script is supposed to run from ppp on-up script hook.") true;
  }

  :local IntName [ /interface/get $Interface name ];
  $LogPrintExit2 info $ScriptName ("PPP interface " . $IntName . " is up.") false;

  /ipv6/dhcp-client/release [ find where interface=$IntName !disabled ];

  :foreach Script in=[ /system/script/find where source~("\n# provides: ppp-on-up\n") ] do={
    :local ScriptName [ /system/script/get $Script name ];
    :do {
      $LogPrintExit2 debug $ScriptName ("Running script: " . $ScriptName) false;
      /system/script/run $Script;
    } on-error={
      $LogPrintExit2 warning $ScriptName ("Running script '" . $ScriptName . "' failed!") false;
    }
  }
}

$Main [ :jobname ] $interface;
