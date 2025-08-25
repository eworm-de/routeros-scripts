#!rsc by RouterOS
# RouterOS script: check-health
# Copyright (c) 2019-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# check for RouterOS health state
# https://rsc.eworm.de/doc/check-health.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global CheckHealthCPUUtilization;
  :global CheckHealthCPUUtilizationNotified;
  :global CheckHealthLast;
  :global CheckHealthRAMUtilizationNotified;
  :global Identity;

  :global FormatLine;
  :global HumanReadableNum;
  :global IfThenElse;
  :global LogPrint;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global ValidateSyntax;

  :local TempToNum do={
    :global CharacterReplace;
    :local T [ :toarray [ $CharacterReplace $1 "." "," ] ];
    :return ($T->0 * 10 + $T->1);
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :local Resource [ /system/resource/get ];

  :set CheckHealthCPUUtilization (($CheckHealthCPUUtilization * 4 + ($Resource->"cpu-load") * 10) / 5);
  :if ($CheckHealthCPUUtilization > 750 && $CheckHealthCPUUtilizationNotified != true) do={
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "abacus,chart-increasing" ] . "Health warning: CPU utilization"); \
      message=("The average CPU utilization on " . $Identity . " is at " . ($CheckHealthCPUUtilization / 10) . "%!") });
    :set CheckHealthCPUUtilizationNotified true;
  }
  :if ($CheckHealthCPUUtilization < 650 && $CheckHealthCPUUtilizationNotified = true) do={
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "abacus,chart-decreasing" ] . "Health recovery: CPU utilization"); \
      message=("The average CPU utilization on " . $Identity . " decreased to " . ($CheckHealthCPUUtilization / 10) . "%.") });
    :set CheckHealthCPUUtilizationNotified false;
  }

  :local CheckHealthRAMUtilization (($Resource->"total-memory" - $Resource->"free-memory") * 100 / $Resource->"total-memory");
  :if ($CheckHealthRAMUtilization >=80 && $CheckHealthRAMUtilizationNotified != true) do={
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "card-file-box,chart-increasing" ] . "Health warning: RAM utilization"); \
      message=("The RAM utilization on " . $Identity . " is at " . $CheckHealthRAMUtilization . "%!\n\n" . \
      [ $FormatLine "total" ([ $HumanReadableNum ($Resource->"total-memory") 1024 ] . "B") 8 ] . "\n" . \
      [ $FormatLine "used" ([ $HumanReadableNum ($Resource->"total-memory" - $Resource->"free-memory") 1024 ] . "B") 8 ] . "\n" . \
      [ $FormatLine "free" ([ $HumanReadableNum ($Resource->"free-memory") 1024 ] . "B") 8 ]) });
    :set CheckHealthRAMUtilizationNotified true;
  }
  :if ($CheckHealthRAMUtilization < 70 && $CheckHealthRAMUtilizationNotified = true) do={
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "card-file-box,chart-decreasing" ] . "Health recovery: RAM utilization"); \
      message=("The RAM utilization on " . $Identity . " decreased to " . $CheckHealthRAMUtilization . "%.") });
    :set CheckHealthRAMUtilizationNotified false;
  }

  :local Plugins [ /system/script/find where name~"^check-health.d/." ];
  :if ([ :len $Plugins ] = 0) do={
    $LogPrint debug $ScriptName ("No plugins installed.");
    :set ExitOK true;
    :error true;
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
        $LogPrint error $ScriptName ("Plugin '" . $PluginVal->"name" . "' failed to run: " . $Err);
      }
    } else={
      $LogPrint error $ScriptName ("Plugin '" . $PluginVal->"name" . "' failed syntax validation, skipping.");
    }
  }

  :foreach PluginName,Discard in=$CheckHealthPlugins do={
    ($CheckHealthPlugins->$PluginName) \
         ("\$CheckHealthPlugins->\"" . $PluginName . "\"");
  }

  :set CheckHealthPlugins;
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
