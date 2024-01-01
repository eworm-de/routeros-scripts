#!rsc by RouterOS
# RouterOS script: firmware-upgrade-reboot
# Copyright (c) 2022-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# install firmware upgrade, and reboot
# https://git.eworm.de/cgit/routeros-scripts/about/doc/firmware-upgrade-reboot.md

:local 0 "firmware-upgrade-reboot";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global LogPrintExit2;
:global ScriptLock;
:global VersionToNum;

$ScriptLock $0;

:local RouterBoard [ /system/routerboard/get ];
:if ($RouterBoard->"current-firmware" = $RouterBoard->"upgrade-firmware") do={
  $LogPrintExit2 info $0 ("Current and upgrade firmware match with version " . \
    $RouterBoard->"current-firmware" . ".") true;
}
:if ([ $VersionToNum ($RouterBoard->"current-firmware") ] > [ $VersionToNum ($RouterBoard->"upgrade-firmware") ]) do={
  $LogPrintExit2 info $0 ("Different firmware version is available, but it is a downgrade. Ignoring.") true;
}

:if ([ /system/routerboard/settings/get auto-upgrade ] = false) do={
  $LogPrintExit2 info $0 ("Firmware version " . $RouterBoard->"upgrade-firmware" . \
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

$LogPrintExit2 info $0 ("Firmware upgrade successful, rebooting.") false;
/system/reboot;
