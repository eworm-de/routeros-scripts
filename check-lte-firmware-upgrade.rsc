#!rsc by RouterOS
# RouterOS script: check-lte-firmware-upgrade
# Copyright (c) 2018-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# check for LTE firmware upgrade, send notification
# https://git.eworm.de/cgit/routeros-scripts/about/doc/check-lte-firmware-upgrade.md

:local 0 "check-lte-firmware-upgrade";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global SentLteFirmwareUpgradeNotification;

:global ScriptLock;

$ScriptLock $0;

:if ([ :typeof $SentLteFirmwareUpgradeNotification ] != "array") do={
  :global SentLteFirmwareUpgradeNotification ({});
}

:local CheckInterface do={
  :local Interface $1;

  :global Identity;
  :global SentLteFirmwareUpgradeNotification;

  :global CharacterReplace;
  :global FormatLine;
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
    $LogPrintExit2 debug $0 ("Could not get latest LTE firmware version for interface " . \
      $IntName . ".") false;
    :return false;
  }

  :if (($Firmware->"installed") = ($Firmware->"latest")) do={
    :if ([ $ScriptFromTerminal $0 ] = true) do={
      $LogPrintExit2 info $0 ("No firmware upgrade available for LTE interface " . $IntName . ".") false;
    }
    :return true;
  }

  :if ([ $ScriptFromTerminal $0 ] = true && \
      [ :len [ /system/script/find where name="unattended-lte-firmware-upgrade" ] ] > 0) do={
    :put ("Do you want to start unattended lte firmware upgrade for interface " . $IntName . "? [y/N]");
    :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
        /system/script/run unattended-lte-firmware-upgrade;
        $LogPrintExit2 info $0 ("Scheduled lte firmware upgrade for interface " . $IntName . "...") false;
      :return true;
    } else={
      :put "Canceled...";
    }
  }

  :if (($SentLteFirmwareUpgradeNotification->$IntName) = ($Firmware->"latest")) do={
    $LogPrintExit2 debug $0 ("Already sent the LTE firmware upgrade notification for version " . \
      ($Firmware->"latest") . ".") false;
    :return false;
  }

  $LogPrintExit2 info $0 ("A new firmware version " . ($Firmware->"latest") . " is available for " . \
    "LTE interface " . $IntName . ".") false;
  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "sparkles" ] . "LTE firmware upgrade"); \
    message=("A new firmware version " . ($Firmware->"latest") . " is available for " . \
      "LTE interface " . $IntName . " on " . $Identity . ".\n\n" . \
      [ $FormatLine "Interface" [ $CharacterReplace ($Info->"manufacturer" . " " . $Info->"model") ("\"") "" ] ] . "\n" . \
      "Firmware version:\n" . \
      [ $FormatLine "    Installed" ($Firmware->"installed") ] . "\n" . \
      [ $FormatLine "    Available" ($Firmware->"latest") ]); silent=true });
  :set ($SentLteFirmwareUpgradeNotification->$IntName) ($Firmware->"latest");
}

:foreach Interface in=[ /interface/lte/find ] do={
  $CheckInterface $Interface;
}
