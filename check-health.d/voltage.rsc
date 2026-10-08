#!rsc by RouterOS
# RouterOS script: check-health.d/voltage
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# check for RouterOS health state - voltage plugin
# https://rsc.eworm.de/doc/check-health.md

:global CheckHealthPlugins;

:set ($CheckHealthPlugins->[ :jobname ]) do={
  :local FuncName   [ :tostr $0 ];
  :local ScriptName [ :tostr $1 ];

  :global CheckHealthLast;
  :global CheckHealthVoltageLow;
  :global CheckHealthVoltagePercent;
  :global Identity;

  :global FormatLine;
  :global IfThenElse;
  :global Translate;
  :global LogPrint;
  :global SendNotification2;
  :global SymbolForNotification;

  :if ([ :len [ /system/health/find where type="V" ] ] = 0) do={
    $LogPrint debug $FuncName ([ $Translate "check-health.voltage.unavailable" ]);
    :return false;
  }

  :foreach Voltage in=[ /system/health/find where type="V" ] do={
    :local Name  [ /system/health/get $Voltage name  ];
    :local Value [ /system/health/get $Voltage value ];

    :if ([ :typeof ($CheckHealthLast->$Name) ] != "nothing") do={
      :local NumCurr [ $TempToNum $Value ];
      :local NumLast [ $TempToNum ($CheckHealthLast->$Name) ];

      :if ($NumLast * (100 + $CheckHealthVoltagePercent) < $NumCurr * 100 || \
           $NumLast * 100 > $NumCurr * (100 + $CheckHealthVoltagePercent)) do={
        $SendNotification2 ({ origin=$ScriptName; \
          subject=([ $SymbolForNotification ("high-voltage-sign,chart-" . [ $IfThenElse ($NumLast < \
            $NumCurr) "in" "de" ] . "creasing") ] . [ $Translate "check-health.warning.subject" { name=$Name } ]); \
          message=([ $Translate "check-health.voltage.jumped" { name=$Name; identity=$Identity; percent=$CheckHealthVoltagePercent; details=([ $FormatLine [ $Translate "check-health.voltage.old" ] ($CheckHealthLast->$Name . " V") 12 ] . "\n" . \
            [ $FormatLine [ $Translate "check-health.voltage.new" ] ($Value . " V") 12 ]) } ]) });
      } else={
        :if ($NumCurr <= $CheckHealthVoltageLow && $NumLast > $CheckHealthVoltageLow) do={
          $SendNotification2 ({ origin=$ScriptName; \
            subject=([ $SymbolForNotification "high-voltage-sign,chart-decreasing" ] . [ $Translate "check-health.voltage.low.subject" { name=$Name } ]); \
            message=([ $Translate "check-health.voltage.low.message" { name=$Name; identity=$Identity; value=$Value } ]) });
        }
        :if ($NumCurr > $CheckHealthVoltageLow && $NumLast <= $CheckHealthVoltageLow) do={
          $SendNotification2 ({ origin=$ScriptName; \
            subject=([ $SymbolForNotification "high-voltage-sign,chart-increasing" ] . [ $Translate "check-health.voltage.recovery.subject" { name=$Name } ]); \
            message=([ $Translate "check-health.voltage.recovery.message" { name=$Name; identity=$Identity; value=$Value } ]) });
        }
      }
    }
    :set ($CheckHealthLast->$Name) $Value;
  }
}
