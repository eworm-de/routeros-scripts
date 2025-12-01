#!rsc by RouterOS
# RouterOS script: unattended-lte-firmware-upgrade
# Copyright (c) 2018-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, scheduler
#
# schedule unattended lte firmware upgrade
# https://rsc.eworm.de/doc/unattended-lte-firmware-upgrade.md

:foreach Interface in=[ /interface/lte/find where running ] do={
  :local Firmware;
  :local IntName [ /interface/lte/get $Interface name ];
  :onerror Err {
    :set Firmware [ /interface/lte/firmware-upgrade $Interface as-value ];
  } do={
    :log debug ("Could not get latest LTE firmware version for interface " . $IntName . ": " . $Err);
  }

  :if ([ :typeof $Firmware ] = "array") do={
    :if (($Firmware->"installed") != ($Firmware->"latest")) do={
      :log info ("Scheduling LTE firmware upgrade for interface " . $IntName . ".");

      :global LTEFirmwareUpgrade do={
        :global LTEFirmwareUpgrade;
        :set LTEFirmwareUpgrade;

        /system/scheduler/remove ($1 . "-firmware-upgrade");
        :onerror Err {
          /interface/lte/firmware-upgrade $1 upgrade=yes;
          :log info ("LTE firmware upgrade on '" . $1 . "' finished, waiting for reset.");
          :delay 240s;
          :local Firmware [ /interface/lte/firmware-upgrade $1 as-value ];
          :if ([ :len ($Firmware->"latest") ] > 0 && \
               ($Firmware->"installed") != ($Firmware->"latest")) do={
            :log warning ("LTE firmware versions still differ. Upgrade failed anyway?");
          }
        } do={
          :log error ("LTE firmware upgrade on '" . $1 . "' failed: " . $Err);
        }
      }

      /system/scheduler/add name=($IntName . "-firmware-upgrade") start-time=startup interval=2s \
        on-event=(":global LTEFirmwareUpgrade; \$LTEFirmwareUpgrade \"" . $IntName . "\";");
    } else={
      :log info ("The LTE firmware is up to date on interface " . $IntName . ".");
    }
  } else={
    :log info ("No LTE firmware information available for interface " . $IntName . ".");
  }
}
