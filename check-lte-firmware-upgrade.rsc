#!rsc by RouterOS
# RouterOS script: check-lte-firmware-upgrade
# Copyright (c) 2018-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.12
#
# check for LTE firmware upgrade, send notification
# https://git.eworm.de/cgit/routeros-scripts/about/doc/check-lte-firmware-upgrade.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local Main do={
  :local ScriptName [ :tostr $1 ];

  :global SentLteFirmwareUpgradeNotification;

  :global ScriptLock;

  $ScriptLock $ScriptName;

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
    :global LogPrintExit2;
    :global ScriptFromTerminal;
    :global SendNotification2;
    :global SymbolForNotification;

    :local IntName [ /interface/lte/get $Interface name ];
    :local Firmware;
    :local Info;
    :do {
      :set Firmware [ /interface/lte/firmware-upgrade $Interface once as-value ];
      :set Info [ /interface/lte/monitor $Interface once as-value ];
    } on-error={
      $LogPrintExit2 debug $ScriptName ("Could not get latest LTE firmware version for interface " . \
        $IntName . ".") false;
      :return false;
    }

    :if ([ :len ($Firmware->"latest") ] = 0) do={
      $LogPrintExit2 info $ScriptName ("An empty string is not a valid version.") false;
      :return false;
    }

    :if (($Firmware->"installed") = ($Firmware->"latest")) do={
      :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
        $LogPrintExit2 info $ScriptName ("No firmware upgrade available for LTE interface " . $IntName . ".") false;
      }
      :return true;
    }

    :if ([ $ScriptFromTerminal $ScriptName ] = true && \
        [ :len [ /system/script/find where name="unattended-lte-firmware-upgrade" ] ] > 0) do={
      :put ("Do you want to start unattended lte firmware upgrade for interface " . $IntName . "? [y/N]");
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          /system/script/run unattended-lte-firmware-upgrade;
          $LogPrintExit2 info $ScriptName ("Scheduled lte firmware upgrade for interface " . $IntName . "...") false;
        :return true;
      } else={
        :put "Canceled...";
      }
    }

    :if (($SentLteFirmwareUpgradeNotification->$IntName) = ($Firmware->"latest")) do={
      $LogPrintExit2 debug $ScriptName ("Already sent the LTE firmware upgrade notification for version " . \
        ($Firmware->"latest") . ".") false;
      :return false;
    }

    $LogPrintExit2 info $ScriptName ("A new firmware version " . ($Firmware->"latest") . " is available for " . \
      "LTE interface " . $IntName . ".") false;
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
}

$Main [ :jobname ];
