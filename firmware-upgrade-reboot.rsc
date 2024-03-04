#!rsc by RouterOS
# RouterOS script: firmware-upgrade-reboot
# Copyright (c) 2022-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.12
#
# install firmware upgrade, and reboot
# https://git.eworm.de/cgit/routeros-scripts/about/doc/firmware-upgrade-reboot.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local Main do={
  :local ScriptName [ :tostr $1 ];

  :global LogPrintExit2;
  :global ScriptLock;
  :global VersionToNum;

  $ScriptLock $ScriptName;

  :local RouterBoard [ /system/routerboard/get ];
  :if ($RouterBoard->"current-firmware" = $RouterBoard->"upgrade-firmware") do={
    $LogPrintExit2 info $ScriptName ("Current and upgrade firmware match with version " . \
      $RouterBoard->"current-firmware" . ".") false;
    :return true;
  }
  :if ([ $VersionToNum ($RouterBoard->"current-firmware") ] > [ $VersionToNum ($RouterBoard->"upgrade-firmware") ]) do={
    $LogPrintExit2 info $ScriptName ("Different firmware version is available, but it is a downgrade. Ignoring.") false;
    :return true;
  }

  :if ([ /system/routerboard/settings/get auto-upgrade ] = false) do={
    $LogPrintExit2 info $ScriptName ("Firmware version " . $RouterBoard->"upgrade-firmware" . \
      " is available, upgrading.") false;
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

  $LogPrintExit2 info $ScriptName ("Firmware upgrade successful, rebooting.") false;
  /system/reboot;
}

$Main [ :jobname ];
