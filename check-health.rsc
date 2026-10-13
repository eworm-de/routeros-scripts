#!rsc by RouterOS
# RouterOS script: check-health
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# check for RouterOS health state
# https://rsc.eworm.de/doc/check-health.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=check-health, schema=46a1c96fc663c6ec3c3f676c07e02aedf8dc2b606ec48848159b601ed88bf852
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"check-health.cpu.recovery.message") "The average CPU utilization on {identity} decreased to {percent}%.";
:set ($LanguageEnglish->"check-health.cpu.recovery.subject") "Health recovery: CPU utilization";
:set ($LanguageEnglish->"check-health.cpu.warning.message") "The average CPU utilization on {identity} is at {percent}%!";
:set ($LanguageEnglish->"check-health.cpu.warning.subject") "Health warning: CPU utilization";
:set ($LanguageEnglish->"check-health.plugins.failed") "Plugin '{name}' failed to run: {error}";
:set ($LanguageEnglish->"check-health.plugins.none") "No plugins installed.";
:set ($LanguageEnglish->"check-health.plugins.syntax") "Plugin '{name}' failed syntax validation, skipping.";
:set ($LanguageEnglish->"check-health.ram.free") "free";
:set ($LanguageEnglish->"check-health.ram.recovery.message") "The RAM utilization on {identity} decreased to {percent}%.";
:set ($LanguageEnglish->"check-health.ram.recovery.subject") "Health recovery: RAM utilization";
:set ($LanguageEnglish->"check-health.ram.total") "total";
:set ($LanguageEnglish->"check-health.ram.used") "used";
:set ($LanguageEnglish->"check-health.ram.warning.message") "The RAM utilization on {identity} is at {percent}%!\0A\0A{details}";
:set ($LanguageEnglish->"check-health.ram.warning.subject") "Health warning: RAM utilization";
:set ($LanguageEnglish->"check-health.recovery.subject") "Health recovery: {name}";
:set ($LanguageEnglish->"check-health.state.failed") "The device '{name}' on {identity} failed!";
:set ($LanguageEnglish->"check-health.state.recovered") "The device '{name}' on {identity} recovered!";
:set ($LanguageEnglish->"check-health.state.unavailable") "Your device does not provide any state health values.";
:set ($LanguageEnglish->"check-health.temperature.high") "The {name} on {identity} is above threshold: {value}\C2\B0C\0A\0AThe average CPU utilization is at {percent}%!";
:set ($LanguageEnglish->"check-health.temperature.recovered") "The {name} on {identity} dropped below threshold: {value}\C2\B0C\0A\0AThe average CPU utilization is at {percent}%!";
:set ($LanguageEnglish->"check-health.temperature.threshold") "No threshold given for {name}, assuming 50C.";
:set ($LanguageEnglish->"check-health.temperature.unavailable") "Your device does not provide any voltage health values.";
:set ($LanguageEnglish->"check-health.voltage.jumped") "The {name} on {identity} jumped more than {percent}%.\0A\0A{details}";
:set ($LanguageEnglish->"check-health.voltage.low.message") "The {name} on {identity} dropped to {value} V below hard limit.";
:set ($LanguageEnglish->"check-health.voltage.low.subject") "Health warning: Low {name}";
:set ($LanguageEnglish->"check-health.voltage.new") "new value";
:set ($LanguageEnglish->"check-health.voltage.old") "old value";
:set ($LanguageEnglish->"check-health.voltage.recovery.message") "The {name} on {identity} recovered to {value} V above hard limit.";
:set ($LanguageEnglish->"check-health.voltage.recovery.subject") "Health recovery: Low {name}";
:set ($LanguageEnglish->"check-health.voltage.unavailable") "Your device does not provide any voltage health values.";
:set ($LanguageEnglish->"check-health.warning.subject") "Health warning: {name}";
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

  :global CheckHealthCPUUtilization;
  :global CheckHealthCPUUtilizationNotified;
  :global CheckHealthLast;
  :global CheckHealthRAMUtilizationNotified;
  :global Identity;

  :global Translate;
  :global FormatLine;
  :global HumanReadableNum;
  :global IfThenElse;
  :global LogPrint;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global ValidateSyntax;

  :local TempToNum do={
    :local T [ :toarray delimiter="." $1 ];
    :return ($T->0 * 10 + $T->1);
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :local Resource [ /system/resource/get ];

  :set CheckHealthCPUUtilization (($CheckHealthCPUUtilization * 4 + ($Resource->"cpu-load") * 10) / 5);
  :if ($CheckHealthCPUUtilization > 750 && $CheckHealthCPUUtilizationNotified != true) do={
    $SendNotification2 ({ origin=$ScriptName; silent=false; \
      subject=([ $SymbolForNotification "abacus,chart-increasing" ] . [ $Translate "check-health.cpu.warning.subject" ]); \
      message=([ $Translate "check-health.cpu.warning.message" ({ identity=$Identity; percent=($CheckHealthCPUUtilization / 10) }) ]) });
    :set CheckHealthCPUUtilizationNotified true;
  }
  :if ($CheckHealthCPUUtilization < 650 && $CheckHealthCPUUtilizationNotified = true) do={
    $SendNotification2 ({ origin=$ScriptName; silent=true; \
      subject=([ $SymbolForNotification "abacus,chart-decreasing" ] . [ $Translate "check-health.cpu.recovery.subject" ]); \
      message=([ $Translate "check-health.cpu.recovery.message" ({ identity=$Identity; percent=($CheckHealthCPUUtilization / 10) }) ]) });
    :set CheckHealthCPUUtilizationNotified false;
  }

  :local CheckHealthRAMUtilization (($Resource->"total-memory" - $Resource->"free-memory") * 100 / $Resource->"total-memory");
  :if ($CheckHealthRAMUtilization >=80 && $CheckHealthRAMUtilizationNotified != true) do={
    $SendNotification2 ({ origin=$ScriptName; silent=false; \
      subject=([ $SymbolForNotification "card-file-box,chart-increasing" ] . [ $Translate "check-health.ram.warning.subject" ]); \
      message=([ $Translate "check-health.ram.warning.message" ({ identity=$Identity; percent=$CheckHealthRAMUtilization; details=([ $FormatLine [ $Translate "check-health.ram.total" ] ([ $HumanReadableNum ($Resource->"total-memory") 1024 ] . "B") 8 ] . "\n" . \
      [ $FormatLine [ $Translate "check-health.ram.used" ] ([ $HumanReadableNum ($Resource->"total-memory" - $Resource->"free-memory") 1024 ] . "B") 8 ] . "\n" . \
      [ $FormatLine [ $Translate "check-health.ram.free" ] ([ $HumanReadableNum ($Resource->"free-memory") 1024 ] . "B") 8 ]) }) ]) });
    :set CheckHealthRAMUtilizationNotified true;
  }
  :if ($CheckHealthRAMUtilization < 70 && $CheckHealthRAMUtilizationNotified = true) do={
    $SendNotification2 ({ origin=$ScriptName; silent=true; \
      subject=([ $SymbolForNotification "card-file-box,chart-decreasing" ] . [ $Translate "check-health.ram.recovery.subject" ]); \
      message=([ $Translate "check-health.ram.recovery.message" ({ identity=$Identity; percent=$CheckHealthRAMUtilization }) ]) });
    :set CheckHealthRAMUtilizationNotified false;
  }

  :local Plugins [ /system/script/find where name~"^check-health\\.d/." ];
  :if ([ :len $Plugins ] = 0) do={
    $LogPrint debug $ScriptName ([ $Translate "check-health.plugins.none" ]);
    :exit;
  }

  :global CheckHealthPlugins ({});
  :if ([ :typeof $CheckHealthLast ] != "array") do={
    :set CheckHealthLast ({});
  }

  :foreach Plugin in=$Plugins do={
    :local PluginVal [ /system/script/get $Plugin ];
    :if ([ $ValidateSyntax ($PluginVal->"source") ] = true) do={
      :onerror Err {
        /system/script/run $Plugin;
      } do={
        $LogPrint error $ScriptName ([ $Translate "check-health.plugins.failed" ({ name=($PluginVal->"name"); error=$Err }) ]);
      }
    } else={
      $LogPrint error $ScriptName ([ $Translate "check-health.plugins.syntax" ({ name=($PluginVal->"name") }) ]);
    }
  }

  :foreach PluginName,Discard in=$CheckHealthPlugins do={
    ($CheckHealthPlugins->$PluginName) \
        ("\$CheckHealthPlugins->\"" . $PluginName . "\"") $ScriptName;
  }

  :set CheckHealthPlugins;
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
