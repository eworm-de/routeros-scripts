#!rsc by RouterOS
# RouterOS script: check-health.d/temperature
# Copyright (c) 2019-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# check for RouterOS health state - temperature plugin
# https://rsc.eworm.de/doc/check-health.md

:global CheckHealthPlugins;

:set ($CheckHealthPlugins->[ :jobname ]) do={
  :local FuncName [ :tostr $0 ];

  :global CheckHealthLast;
  :global CheckHealthTemperature;
  :global CheckHealthTemperatureDeviation;
  :global CheckHealthTemperatureNotified;
  :global Identity;

  :global LogPrint;
  :global SendNotification2;
  :global SymbolForNotification;

  :if ([ :len [ /system/health/find where type="C" ] ] = 0) do={
    $LogPrint debug $FuncName ("Your device does not provide any voltage health values.");
    :return false;
  }

  :local TempToNum do={
    :global CharacterReplace;
    :local T [ :toarray [ $CharacterReplace $1 "." "," ] ];
    :return ($T->0 * 10 + $T->1);
  }

  :if ([ :typeof $CheckHealthTemperatureNotified ] != "array") do={
    :set CheckHealthTemperatureNotified ({});
  }

  :foreach Temperature in=[ /system/health/find where type="C" ] do={
    :local Name  [ /system/health/get $Temperature name  ];
    :local Value [ /system/health/get $Temperature value ];

    :if ([ :typeof ($CheckHealthLast->$Name) ] != "nothing") do={
      :if ([ :typeof ($CheckHealthTemperature->$Name) ] != "num" ) do={
        $LogPrint info $FuncName ("No threshold given for " . $Name . ", assuming 50C.");
        :set ($CheckHealthTemperature->$Name) 50;
      }
      :local Validate [ /system/health/get [ find where name=$Name ] value ];
      :while ($Value != $Validate) do={
        :set Value $Validate;
        :set Validate [ /system/health/get [ find where name=$Name ] value ];
      }
      :if ($Value > $CheckHealthTemperature->$Name && \
           $CheckHealthTemperatureNotified->$Name != true) do={
        $SendNotification2 ({ origin=$FuncName; \
          subject=([ $SymbolForNotification "fire" ] . "Health warning: " . $Name); \
          message=("The " . $Name . " on " . $Identity . " is above threshold: " . \
            $Value . "\C2\B0" . "C") });
        :set ($CheckHealthTemperatureNotified->$Name) true;
      }
      :if ($Value <= ($CheckHealthTemperature->$Name - $CheckHealthTemperatureDeviation) && \
           $CheckHealthTemperatureNotified->$Name = true) do={
        $SendNotification2 ({ origin=$FuncName; \
          subject=([ $SymbolForNotification "white-heavy-check-mark" ] . "Health recovery: " . $Name); \
          message=("The " . $Name . " on " . $Identity . " dropped below threshold: " .  \
            $Value . "\C2\B0" . "C") });
        :set ($CheckHealthTemperatureNotified->$Name) false;
      }
    }
    :set ($CheckHealthLast->$Name) $Value;
  }
}
