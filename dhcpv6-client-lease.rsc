#!rsc by RouterOS
# RouterOS script: dhcpv6-client-lease
# Copyright (c) 2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# run scripts on IPv6 DHCP client lease
# https://rsc.eworm.de/doc/dhcpv6-client-lease.md

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global Grep;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName 10 ] = false) do={
    :exit;
  }

  :if (([ :typeof $"na-address" ] = "nothing" || [ :typeof $"na-valid" ] = "nothing") && \
       ([ :typeof $"pd-prefix" ] = "nothing" || [ :typeof $"pd-valid" ] = "nothing")) do={
    $LogPrint error $ScriptName ("This script is supposed to run from ipv6 dhcp-client.");
    :exit;
  }

  :global DHCPv6ClientLeaseVars {
    "na-address"=$"na-address";
    "na-valid"=$"na-valid";
    "pd-prefix"=$"pd-prefix";
    "pd-valid"=$"pd-valid";
    "options"=$"options" };

  :local RunOrder ({});
  :foreach Script in=[ /system/script/find where source~("\n# provides: dhcpv6-client-lease\\b") ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local Store [ $ParseKeyValueStore [ $Grep ($ScriptVal->"source") ("\23 provides: dhcpv6-client-lease, ") ] ];

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

  :set DHCPv6ClientLeaseVars;
} do={
  :global DHCPv6ClientLeaseVars; :set DHCPv6ClientLeaseVars;
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
