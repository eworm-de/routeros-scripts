#!rsc by RouterOS
# RouterOS script: firmware-upgrade-reboot
# Copyright (c) 2022-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# install firmware upgrade, and reboot
# https://rsc.eworm.de/doc/firmware-upgrade-reboot.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local ExitOK false;
:do {
  :local ScriptName [ :jobname ];

  :global LogPrint;
  :global ScriptLock;
  :global VersionToNum;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :local RouterBoard [ /system/routerboard/get ];
  :if ($RouterBoard->"current-firmware" = $RouterBoard->"upgrade-firmware") do={
    $LogPrint info $ScriptName ("Current and upgrade firmware match with version " . \
      $RouterBoard->"current-firmware" . ".");
    :set ExitOK true;
    :error true;
  }
  :if ([ $VersionToNum ($RouterBoard->"current-firmware") ] > [ $VersionToNum ($RouterBoard->"upgrade-firmware") ]) do={
    $LogPrint info $ScriptName ("Different firmware version is available, but it is a downgrade. Ignoring.");
    :set ExitOK true;
    :error true;
  }

  :if ([ /system/routerboard/settings/get auto-upgrade ] = false) do={
    $LogPrint info $ScriptName ("Firmware version " . $RouterBoard->"upgrade-firmware" . \
      " is available, upgrading.");
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

  $LogPrint info $ScriptName ("Firmware upgrade successful, rebooting.");
  /system/reboot;
} on-error={
  :global ExitError; $ExitError $ExitOK [ :jobname ];
}
