#!rsc by RouterOS
# RouterOS script: firmware-upgrade-reboot
# Copyright (c) 2022-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# install firmware upgrade, and reboot
# https://rsc.eworm.de/doc/firmware-upgrade-reboot.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=firmware-upgrade-reboot, schema=6029d1d4da514989c7a64a3ae717c2ca8f5f42f295ad0d203b8343cf7a2944a5
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"firmware-upgrade-reboot.current") "Current and upgrade firmware match with version {version}.";
:set ($LanguageEnglish->"firmware-upgrade-reboot.downgrade") "Different firmware version is available, but it is a downgrade. Ignoring.";
:set ($LanguageEnglish->"firmware-upgrade-reboot.reboot") "Firmware upgrade successful, rebooting.";
:set ($LanguageEnglish->"firmware-upgrade-reboot.upgrade") "Firmware version {version} is available, upgrading.";
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

  :global LogPrint;
  :global Translate;
  :global ScriptLock;
  :global VersionToNum;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :local RouterBoard [ /system/routerboard/get ];
  :if ($RouterBoard->"current-firmware" = $RouterBoard->"upgrade-firmware") do={
    $LogPrint info $ScriptName [ $Translate "firmware-upgrade-reboot.current" \
        ({ version=($RouterBoard->"current-firmware") }) ];
    :exit;
  }
  :if ([ $VersionToNum ($RouterBoard->"current-firmware") ] > [ $VersionToNum ($RouterBoard->"upgrade-firmware") ]) do={
    $LogPrint info $ScriptName [ $Translate "firmware-upgrade-reboot.downgrade" ];
    :exit;
  }

  :if ([ /system/routerboard/settings/get auto-upgrade ] = false) do={
    $LogPrint info $ScriptName [ $Translate "firmware-upgrade-reboot.upgrade" \
        ({ version=($RouterBoard->"upgrade-firmware") }) ];
    /system/routerboard/upgrade;
  }

  :while ([ :len [ /log/find where topics=({"system";"info";"critical"}) \
      message="Firmware upgraded successfully, please reboot for changes to take effect!" ] ] = 0) do={
    :delay 1s;
  }

  :local Uptime [ /system/resource/get uptime ];
  :if ($Uptime < 1m) do={
    :delay $Uptime;
  }

  $LogPrint info $ScriptName [ $Translate "firmware-upgrade-reboot.reboot" ];
  /system/reboot;
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
