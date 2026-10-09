#!rsc by RouterOS
# RouterOS script: dhcpv6-client-lease
# Copyright (c) 2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# run scripts on IPv6 DHCP client lease
# https://rsc.eworm.de/doc/dhcpv6-client-lease.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=dhcpv6-client-lease, schema=6945e4d13819da10f471d905a5fc37284b6cf1e482d9a7b526483b754951e02a
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"dhcpv6-client-lease.context.invalid") "This script is supposed to run from ipv6 dhcp-client.";
:set ($LanguageEnglish->"dhcpv6-client-lease.script.failed") "Running script '{name}' failed: {error}";
:set ($LanguageEnglish->"dhcpv6-client-lease.script.running") "Running script with order {order}: {name}";
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
  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName 10 ] = false) do={
    :exit;
  }

  :if (([ :typeof $"na-address" ] = "nothing" || [ :typeof $"na-valid" ] = "nothing") && \
       ([ :typeof $"pd-prefix" ] = "nothing" || [ :typeof $"pd-valid" ] = "nothing")) do={
    $LogPrint error $ScriptName [ $Translate "dhcpv6-client-lease.context.invalid" ];
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
      $LogPrint debug $ScriptName [ $Translate "dhcpv6-client-lease.script.running" \
          ({ order=$Order; name=$Script }) ];
      /system/script/run $Script;
    } do={
      $LogPrint warning $ScriptName [ $Translate "dhcpv6-client-lease.script.failed" \
          ({ name=$Script; error=$Err }) ];
    }
  }

  :set DHCPv6ClientLeaseVars;
} do={
  :global DHCPv6ClientLeaseVars; :set DHCPv6ClientLeaseVars;
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
