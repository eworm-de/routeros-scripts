#!rsc by RouterOS
# RouterOS script: dhcpv4-server-lease
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# run scripts on IPv4 DHCP server lease
# https://rsc.eworm.de/doc/dhcpv4-server-lease.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=dhcpv4-server-lease, schema=e8bd70cbac2cb60d46fce97c5cd6f4d6f35e4039991ffa0fb5fd3e1e1ac986c3
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"dhcpv4-server-lease.assigned") "DHCP Server {server} assigned lease {address} to {mac}";
:set ($LanguageEnglish->"dhcpv4-server-lease.context.invalid") "This script is supposed to run from ip dhcp-server.";
:set ($LanguageEnglish->"dhcpv4-server-lease.deassigned") "DHCP Server {server} deassigned lease {address} to {mac}";
:set ($LanguageEnglish->"dhcpv4-server-lease.script.failed") "Running script '{name}' failed: {error}";
:set ($LanguageEnglish->"dhcpv4-server-lease.script.running") "Running script with order {order}: {name}";
:set ($LanguageEnglish->"dhcpv4-server-lease.waiting") "More invocations are waiting, exiting early.";
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

  :global Grep;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ :typeof $leaseActIP ] = "nothing" || \
       [ :typeof $leaseActMAC ] = "nothing" || \
       [ :typeof $leaseServerName ] = "nothing" || \
       [ :typeof $leaseBound ] = "nothing") do={
    $LogPrint error $ScriptName [ $Translate "dhcpv4-server-lease.context.invalid" ];
    :exit;
  }

  $LogPrint debug $ScriptName [ $IfThenElse ($leaseBound = 0) \
      [ $Translate "dhcpv4-server-lease.deassigned" \
          ({ server=$leaseServerName; address=$leaseActIP; mac=$leaseActMAC }) ] \
      [ $Translate "dhcpv4-server-lease.assigned" \
          ({ server=$leaseServerName; address=$leaseActIP; mac=$leaseActMAC }) ] ];

  :if ([ $ScriptLock $ScriptName 10 ] = false) do={
    :exit;
  }

  :if ([ :len [ /system/script/job/find where script=$ScriptName ] ] > 1) do={
    $LogPrint debug $ScriptName [ $Translate "dhcpv4-server-lease.waiting" ];
    :exit;
  }

  :local RunOrder ({});
  :foreach Script in=[ /system/script/find where source~("\n# provides: dhcpv4-server-lease\\b") ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local Store [ $ParseKeyValueStore [ $Grep ($ScriptVal->"source") ("\23 provides: dhcpv4-server-lease, ") ] ];

    :set ($RunOrder->($Store->"order" . "-" . $ScriptVal->"name")) ($ScriptVal->"name");
  }

  :foreach Order,Script in=$RunOrder do={
    :onerror Err {
      $LogPrint debug $ScriptName [ $Translate "dhcpv4-server-lease.script.running" \
          ({ order=$Order; name=$Script }) ];
      /system/script/run $Script;
    } do={
      $LogPrint warning $ScriptName [ $Translate "dhcpv4-server-lease.script.failed" \
          ({ name=$Script; error=$Err }) ];
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
