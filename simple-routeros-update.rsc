#!rsc by Guillen
#
# Script: simple-routeros-update.rsc
#
# Copied and adaptated from RouterOS script: packages-update
# Copyright (c) 2019-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# download packages and reboot for installation
# https://rsc.eworm.de/doc/packages-update.md
#
# RouterOS upgrade for a new or repurposed Mikrotik.
# Works even with very old RouterOS versions
# WARNING: reboots router after each upgrade
#
{:put "START script simple-routeros-update"};

{
  :local ScriptName "simple-routeros-update";
  :local LogPrint;

  # Simplified LogPrint
  :set LogPrint do={
    :local Name     [ :tostr $1 ];
    :local Message  [ :tostr $2 ];

    :log info ( $Name . ": " . $Message);
    :put ( $Name . ": " . $Message);
  }

  #
  # Main block:
  #

  $LogPrint $ScriptName "Checking for updates...";
  /system/package/update/check-for-updates without-paging;
  $LogPrint $ScriptName "Installing updates (if any) ...";
  /system/package/update/install without-paging;

  $LogPrint $ScriptName "Checking firmware upgrade ...";

  :local RouterBoard [ /system/routerboard/get ];
  :if ($RouterBoard->"current-firmware" = $RouterBoard->"upgrade-firmware") do={
    $LogPrint $ScriptName ("Firmware already updated:" . $RouterBoard->"current-firmware" . ".");
  } else={
    :if ([ /system/routerboard/settings/get auto-upgrade ] = false) do={
      $LogPrint $ScriptName ("Firmware " . $RouterBoard->"upgrade-firmware" . " available, upgrading.");
      :delay 5s;
      /system/routerboard/upgrade;
      $LogPrint $ScriptName ("Rebooting...");
      :delay 5s;
      /system/reboot;
     }
  }
};

{:put "END script simple-routeros-update"};

