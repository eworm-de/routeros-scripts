#!rsc by RouterOS
# RouterOS script: check-health.d/temperature
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# check for RouterOS health state - temperature plugin
# https://rsc.eworm.de/doc/check-health.md

:global CheckHealthPlugins;

:set ($CheckHealthPlugins->[ :jobname ]) do={
  :local FuncName   [ :tostr $0 ];
  :local ScriptName [ :tostr $1 ];

  :global CheckHealthCPUUtilization;
  :global CheckHealthLast;
  :global CheckHealthTemperature;
  :global CheckHealthTemperatureDeviation;
  :global CheckHealthTemperatureNotified;
  :global Identity;

  :global Translate;
  :global LogPrint;
  :global SendNotification2;
  :global SymbolForNotification;

  :if ([ :len [ /system/health/find where type="C" ] ] = 0) do={
    $LogPrint debug $FuncName ([ $Translate "check-health.temperature.unavailable" ]);
    :return false;
  }

  :local TempToNum do={
    :local T [ :toarray delimiter="." $1 ];
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
        $LogPrint info $FuncName ([ $Translate "check-health.temperature.threshold" ({ name=$Name }) ]);
        :set ($CheckHealthTemperature->$Name) 50;
      }
      :local Validate [ /system/health/get [ find where name=$Name ] value ];
      :while ($Value != $Validate) do={
        :set Value $Validate;
        :set Validate [ /system/health/get [ find where name=$Name ] value ];
      }
      :if ($Value > $CheckHealthTemperature->$Name && \
           $CheckHealthTemperatureNotified->$Name != true) do={
        $SendNotification2 ({ origin=$ScriptName; \
          subject=([ $SymbolForNotification "fire" ] . [ $Translate "check-health.warning.subject" ({ name=$Name }) ]); \
          message=([ $Translate "check-health.temperature.high" ({ name=$Name; identity=$Identity; value=$Value; percent=($CheckHealthCPUUtilization / 10) }) ]) });
        :set ($CheckHealthTemperatureNotified->$Name) true;
      }
      :if ($Value <= ($CheckHealthTemperature->$Name - $CheckHealthTemperatureDeviation) && \
           $CheckHealthTemperatureNotified->$Name = true) do={
        $SendNotification2 ({ origin=$ScriptName; \
          subject=([ $SymbolForNotification "white-heavy-check-mark" ] . [ $Translate "check-health.recovery.subject" ({ name=$Name }) ]); \
          message=([ $Translate "check-health.temperature.recovered" ({ name=$Name; identity=$Identity; value=$Value; percent=($CheckHealthCPUUtilization / 10) }) ]) });
        :set ($CheckHealthTemperatureNotified->$Name) false;
      }
    }
    :set ($CheckHealthLast->$Name) $Value;
  }
}
