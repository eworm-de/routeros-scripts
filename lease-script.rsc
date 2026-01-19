#!rsc by RouterOS
# RouterOS script: lease-script
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.19
#
# run scripts on DHCP lease
# https://rsc.eworm.de/doc/lease-script.md

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
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
    :exit;
  }

  $LogPrint debug $ScriptName ("DHCP Server " . $leaseServerName . " " . [ $IfThenElse ($leaseBound = 0) \
    "de" "" ] . "assigned lease " . $leaseActIP . " to " . $leaseActMAC);

  :if ([ $ScriptLock $ScriptName 10 ] = false) do={
    :exit;
  }

  :if ([ :len [ /system/script/job/find where script=$ScriptName ] ] > 1) do={
    $LogPrint debug $ScriptName ("More invocations are waiting, exiting early.");
    :exit;
  }

  :local RunOrder ({});
  :foreach Script in=[ /system/script/find where source~("\n# provides: lease-script\\b") ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local Store [ $ParseKeyValueStore [ $Grep ($ScriptVal->"source") ("\23 provides: lease-script, ") ] ];

    :set ($RunOrder->($Store->"order" . "-" . $ScriptVal->"name")) ($ScriptVal->"name");
  }

  :foreach Order,Script in=$RunOrder do={
    :onerror Err {
      $LogPrint debug $ScriptName ("Running script with order " . $Order . ": " . $Script);
      /system/script/run $Script;
    } do={
      $LogPrint warning $ScriptName ("Running script '" . $Script . "' failed: " . $Err);
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
