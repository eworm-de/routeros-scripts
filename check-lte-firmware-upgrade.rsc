#!rsc by RouterOS
# RouterOS script: check-lte-firmware-upgrade
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.19
#
# check for LTE firmware upgrade, send notification
# https://rsc.eworm.de/doc/check-lte-firmware-upgrade.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global SentLteFirmwareUpgradeNotification;

  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :if ([ :typeof $SentLteFirmwareUpgradeNotification ] != "array") do={
    :global SentLteFirmwareUpgradeNotification ({});
  }

  :local CheckInterface do={
    :local ScriptName $1;
    :local Interface  $2;

    :global Identity;
    :global SentLteFirmwareUpgradeNotification;

    :global FormatLine;
    :global IfThenElse;
    :global LogPrint;
    :global ScriptFromTerminal;
    :global SendNotification2;
    :global SymbolForNotification;

    :local IntName [ /interface/lte/get $Interface name ];
    :local Firmware;
    :local Info;
    :onerror Err {
      :set Firmware [ /interface/lte/firmware-upgrade $Interface as-value ];
      :set Info [ /interface/lte/monitor $Interface once as-value ];
    } do={
      $LogPrint debug $ScriptName ("Could not get latest LTE firmware version for interface " . \
        $IntName . ": " . $Err);
      :return false;
    }

    :if ([ :len ($Firmware->"latest") ] = 0) do={
      $LogPrint info $ScriptName ("An empty string is not a valid version.");
      :return false;
    }

    :if (($Firmware->"installed") = ($Firmware->"latest")) do={
      :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
        $LogPrint info $ScriptName ("No firmware upgrade available for LTE interface " . $IntName . ".");
      }
      :return true;
    }

    :if ([ $ScriptFromTerminal $ScriptName ] = true && \
        [ :len [ /system/script/find where name="unattended-lte-firmware-upgrade" ] ] > 0) do={
      :put ("Do you want to start unattended lte firmware upgrade for interface " . $IntName . "? [y/N]");
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          /system/script/run unattended-lte-firmware-upgrade;
          $LogPrint info $ScriptName ("Scheduled lte firmware upgrade for interface " . $IntName . "...");
        :return true;
      } else={
        :put "Canceled...";
      }
    }

    :if (($SentLteFirmwareUpgradeNotification->$IntName) = ($Firmware->"latest")) do={
      $LogPrint debug $ScriptName ("Already sent the LTE firmware upgrade notification for version " . \
        ($Firmware->"latest") . ".");
      :return false;
    }

    $LogPrint info $ScriptName ("A new firmware version " . ($Firmware->"latest") . " is available for " . \
      "LTE interface " . $IntName . ".");
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "sparkles" ] . "LTE firmware upgrade"); \
      message=("A new firmware version " . ($Firmware->"latest") . " is available for " . \
        "LTE interface " . $IntName . " on " . $Identity . ".\n\n" . \
        [ $IfThenElse ([ :len ($Info->"manufacturer") ] > 0) ([ $FormatLine "Manufacturer" ($Info->"manufacturer") ] . "\n") ] . \
        [ $IfThenElse ([ :len ($Info->"model") ] > 0) ([ $FormatLine "Model" ($Info->"model") ] . "\n") ] . \
        [ $IfThenElse ([ :len ($Info->"revision") ] > 0) ([ $FormatLine "Revision" ($Info->"revision") ] . "\n") ] . \
        "Firmware version:\n" . \
        [ $FormatLine "    Installed" ($Firmware->"installed") ] . "\n" . \
        [ $FormatLine "    Available" ($Firmware->"latest") ]); silent=true });
    :set ($SentLteFirmwareUpgradeNotification->$IntName) ($Firmware->"latest");
  }

  :foreach Interface in=[ /interface/lte/find ] do={
    $CheckInterface $ScriptName $Interface;
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
