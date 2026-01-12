#!rsc by RouterOS
# RouterOS script: check-health.d/voltage
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.17
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
  :global LogPrint;
  :global SendNotification2;
  :global SymbolForNotification;

  :if ([ :len [ /system/health/find where type="V" ] ] = 0) do={
    $LogPrint debug $FuncName ("Your device does not provide any voltage health values.");
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
            $NumCurr) "in" "de" ] . "creasing") ] . "Health warning: " . $Name); \
          message=("The " . $Name . " on " . $Identity . " jumped more than " . $CheckHealthVoltagePercent . "%.\n\n" . \
            [ $FormatLine "old value" ($CheckHealthLast->$Name . " V") 12 ] . "\n" . \
            [ $FormatLine "new value" ($Value . " V") 12 ]) });
      } else={ 
        :if ($NumCurr <= $CheckHealthVoltageLow && $NumLast > $CheckHealthVoltageLow) do={ 
          $SendNotification2 ({ origin=$ScriptName; \
            subject=([ $SymbolForNotification "high-voltage-sign,chart-decreasing" ] . "Health warning: Low " . $Name); \ 
            message=("The " . $Name . " on " . $Identity . " dropped to " . $Value . " V below hard limit.") }); 
        } 
        :if ($NumCurr > $CheckHealthVoltageLow && $NumLast <= $CheckHealthVoltageLow) do={ 
          $SendNotification2 ({ origin=$ScriptName; \
            subject=([ $SymbolForNotification "high-voltage-sign,chart-increasing" ] . "Health recovery: Low " . $Name); \ 
            message=("The " . $Name . " on " . $Identity . " recovered to " . $Value . " V above hard limit.") }); 
        }
      }
    }
    :set ($CheckHealthLast->$Name) $Value;
  }
}
