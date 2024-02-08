#!rsc by RouterOS
# RouterOS script: unattended-lte-firmware-upgrade
# Copyright (c) 2018-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# schedule unattended lte firmware upgrade
# https://git.eworm.de/cgit/routeros-scripts/about/doc/unattended-lte-firmware-upgrade.md

:foreach Interface in=[ /interface/lte/find where running ] do={
  :local Firmware;
  :local IntName [ /interface/lte/get $Interface name ];
  :do {
    :set Firmware [ /interface/lte/firmware-upgrade $Interface once as-value ];
  } on-error={
    :log debug ("Could not get latest LTE firmware version for interface " . $IntName . ".");
  }

  :if ([ :typeof $Firmware ] = "array") do={
    :if (($Firmware->"installed") != ($Firmware->"latest")) do={
      :log info ("Scheduling LTE firmware upgrade for interface " . $IntName . ".");

      :global LTEFirmwareUpgrade do={
        :global LTEFirmwareUpgrade;
        :set LTEFirmwareUpgrade;

        /system/scheduler/remove ($1 . "-firmware-upgrade");
        :do {
          /interface/lte/firmware-upgrade $1 upgrade=yes;
          :log info ("LTE firmware upgrade on '" . $1 . "' finished, waiting for reset.");
          :delay 240s;
          :local Firmware [ /interface/lte/firmware-upgrade $1 once as-value ];
          :if (($Firmware->"installed") != ($Firmware->"latest")) do={
            :log warning ("LTE firmware versions still differ. Resetting again...");
            /interface/lte/at-chat $1 input="AT+RESET";
          }
        } on-error={
          :log error ("LTE firmware upgrade on '" . $1 . "' failed.");
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
