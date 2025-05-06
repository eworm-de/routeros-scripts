#!rsc by RouterOS
# RouterOS script: lease-script
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# run scripts on DHCP lease
# https://rsc.eworm.de/doc/lease-script.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local ExitOK false;
:onerror Err {
  :local ScriptName [ :jobname ];

  :global Grep;
  :global IfThenElse;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ :typeof $leaseActIP ] = "nothing" || \
       [ :typeof $leaseActMAC ] = "nothing" || \
       [ :typeof $leaseServerName ] = "nothing" || \
       [ :typeof $leaseBound ] = "nothing") do={
    $LogPrint error $ScriptName ("This script is supposed to run from ip dhcp-server.");
    :set ExitOK true;
    :error false;
  }

  $LogPrint debug $ScriptName ("DHCP Server " . $leaseServerName . " " . [ $IfThenElse ($leaseBound = 0) \
    "de" "" ] . "assigned lease " . $leaseActIP . " to " . $leaseActMAC);

  :if ([ $ScriptLock $ScriptName 10 ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :if ([ :len [ /system/script/job/find where script=$ScriptName ] ] > 1) do={
    $LogPrint debug $ScriptName ("More invocations are waiting, exiting early.");
    :set ExitOK true;
    :error true;
  }

  :local RunOrder ({});
  :foreach Script in=[ /system/script/find where source~("\n# provides: lease-script\\b") ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local Store [ $ParseKeyValueStore [ $Grep ($ScriptVal->"source") ("\23 provides: lease-script, ") ] ];

    :set ($RunOrder->($Store->"order" . "-" . $ScriptVal->"name")) ($ScriptVal->"name");
  }

  :foreach Order,Script in=$RunOrder do={
    :do {
      $LogPrint debug $ScriptName ("Running script with order " . $Order . ": " . $Script);
      /system/script/run $Script;
    } on-error={
      $LogPrint warning $ScriptName ("Running script '" . $Script . "' failed!");
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
