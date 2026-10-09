#!rsc by RouterOS
# RouterOS script: check-lte-firmware-upgrade
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# check for LTE firmware upgrade, send notification
# https://rsc.eworm.de/doc/check-lte-firmware-upgrade.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=check-lte-firmware-upgrade, schema=48481740f1c9bb358194e5fc7b620f4ae430d0a89771919bb68cf54ad8f44eee
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"check-lte-firmware-upgrade.already.sent") "Already sent the LTE firmware upgrade notification for version {version}.";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.available.log") "A new firmware version {version} is available for LTE interface {interface}.";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.canceled") "Canceled...";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.current") "No firmware upgrade available for LTE interface {interface}.";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.fetch.failed") "Could not get latest LTE firmware version for interface {interface}: {error}";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.label.available") "    Available";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.label.firmware") "Firmware version:\0A";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.label.installed") "    Installed";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.label.manufacturer") "Manufacturer";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.label.model") "Model";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.label.revision") "Revision";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.message") "A new firmware version {version} is available for LTE interface {interface} on {identity}.\0A\0A{details}";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.prompt") "Do you want to start unattended lte firmware upgrade for interface {interface}? [y/N]";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.scheduled") "Scheduled lte firmware upgrade for interface {interface}...";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.subject") "LTE firmware upgrade";
:set ($LanguageEnglish->"check-lte-firmware-upgrade.version.empty") "An empty string is not a valid version.";
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global SentLteFirmwareUpgradeNotification;

  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
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
    :global Translate;
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
      $LogPrint debug $ScriptName ([ $Translate "check-lte-firmware-upgrade.fetch.failed" ({ interface=$IntName; error=$Err }) ]);
      :return false;
    }

    :if ([ :len ($Firmware->"latest") ] = 0) do={
      $LogPrint info $ScriptName ([ $Translate "check-lte-firmware-upgrade.version.empty" ]);
      :return false;
    }

    :if (($Firmware->"installed") = ($Firmware->"latest")) do={
      :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
        $LogPrint info $ScriptName ([ $Translate "check-lte-firmware-upgrade.current" ({ interface=$IntName }) ]);
      }
      :return true;
    }

    :if ([ $ScriptFromTerminal $ScriptName ] = true && \
        [ :len [ /system/script/find where name="unattended-lte-firmware-upgrade" ] ] > 0) do={
      :put ([ $Translate "check-lte-firmware-upgrade.prompt" ({ interface=$IntName }) ]);
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          /system/script/run unattended-lte-firmware-upgrade;
          $LogPrint info $ScriptName ([ $Translate "check-lte-firmware-upgrade.scheduled" ({ interface=$IntName }) ]);
        :return true;
      } else={
        :put [ $Translate "check-lte-firmware-upgrade.canceled" ];
      }
    }

    :if (($SentLteFirmwareUpgradeNotification->$IntName) = ($Firmware->"latest")) do={
      $LogPrint debug $ScriptName ([ $Translate "check-lte-firmware-upgrade.already.sent" ({ version=($Firmware->"latest") }) ]);
      :return false;
    }

    $LogPrint info $ScriptName ([ $Translate "check-lte-firmware-upgrade.available.log" ({ version=($Firmware->"latest"); interface=$IntName }) ]);
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "sparkles" ] . [ $Translate "check-lte-firmware-upgrade.subject" ]); \
      message=([ $Translate "check-lte-firmware-upgrade.message" ({ version=($Firmware->"latest"); interface=$IntName; identity=$Identity; details=([ $IfThenElse ([ :len ($Info->"manufacturer") ] > 0) ([ $FormatLine [ $Translate "check-lte-firmware-upgrade.label.manufacturer" ] ($Info->"manufacturer") ] . "\n") ] . \
        [ $IfThenElse ([ :len ($Info->"model") ] > 0) ([ $FormatLine [ $Translate "check-lte-firmware-upgrade.label.model" ] ($Info->"model") ] . "\n") ] . \
        [ $IfThenElse ([ :len ($Info->"revision") ] > 0) ([ $FormatLine [ $Translate "check-lte-firmware-upgrade.label.revision" ] ($Info->"revision") ] . "\n") ] . \
        [ $Translate "check-lte-firmware-upgrade.label.firmware" ] . \
        [ $FormatLine [ $Translate "check-lte-firmware-upgrade.label.installed" ] ($Firmware->"installed") ] . "\n" . \
        [ $FormatLine [ $Translate "check-lte-firmware-upgrade.label.available" ] ($Firmware->"latest") ]) }) ]); silent=true });
    :set ($SentLteFirmwareUpgradeNotification->$IntName) ($Firmware->"latest");
  }

  :foreach Interface in=[ /interface/lte/find ] do={
    $CheckInterface $ScriptName $Interface;
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
