#!rsc by RouterOS
# RouterOS script: ppp-on-up
# Copyright (c) 2013-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.13
#
# run scripts on ppp up
# https://git.eworm.de/cgit/routeros-scripts/about/doc/ppp-on-up.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global LogPrint;

  :local Interface $interface;

  :if ([ :typeof $Interface ] = "nothing") do={
    $LogPrint error $ScriptName ("This script is supposed to run from ppp on-up script hook.");
    :error false;
  }

  :local IntName [ /interface/get $Interface name ];
  $LogPrint info $ScriptName ("PPP interface " . $IntName . " is up.");

  /ipv6/dhcp-client/release [ find where interface=$IntName !disabled ];

  :foreach Script in=[ /system/script/find where source~("\n# provides: ppp-on-up\n") ] do={
    :local ScriptName [ /system/script/get $Script name ];
    :do {
      $LogPrint debug $ScriptName ("Running script: " . $ScriptName);
      /system/script/run $Script;
    } on-error={
      $LogPrint warning $ScriptName ("Running script '" . $ScriptName . "' failed!");
    }
  }
} on-error={ }
