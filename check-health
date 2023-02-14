#!rsc by RouterOS
# RouterOS script: check-health
# Copyright (c) 2019-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# check for RouterOS health state
# https://git.eworm.de/cgit/routeros-scripts/about/doc/check-health.md

:local 0 "check-health";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global CheckHealthCPUUtilization;
:global CheckHealthCPUUtilizationNotified;
:global CheckHealthFreeRAMNotified;
:global CheckHealthLast;
:global CheckHealthTemperature;
:global CheckHealthTemperatureDeviation;
:global CheckHealthTemperatureNotified;
:global CheckHealthVoltageLow;
:global CheckHealthVoltagePercent;
:global Identity;

:global IfThenElse;
:global LogPrintExit2;
:global ScriptLock;
:global SendNotification2;
:global SymbolForNotification;

:local TempToNum do={
  :global CharacterReplace;
  :local T [ :toarray [ $CharacterReplace $1 "." "," ] ];
  :return ($T->0 * 10 + $T->1);
}

$ScriptLock $0;

:local Resource [ /system/resource/get ];

:set CheckHealthCPUUtilization (($CheckHealthCPUUtilization * 4 + ($Resource->"cpu-load") * 10) / 5);
:if ($CheckHealthCPUUtilization > 750 && $CheckHealthCPUUtilizationNotified != true) do={
  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "abacus,chart-increasing" ] . "Health warning: CPU utilization"); \
    message=("The average CPU utilization on " . $Identity . " is at " . ($CheckHealthCPUUtilization / 10) . "%!") });
  :set CheckHealthCPUUtilizationNotified true;
}
:if ($CheckHealthCPUUtilization < 650 && $CheckHealthCPUUtilizationNotified = true) do={
  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "abacus,chart-decreasing" ] . "Health recovery: CPU utilization"); \
    message=("The average CPU utilization on " . $Identity . " decreased to " . ($CheckHealthCPUUtilization / 10) . "%.") });
  :set CheckHealthCPUUtilizationNotified false;
}

:local CheckHealthFreeRAM ($Resource->"free-memory" * 100  / $Resource->"total-memory");
:if ($CheckHealthFreeRAM < 20 && $CheckHealthFreeRAMNotified != true) do={
  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "card-file-box,chart-decreasing" ] . "Health warning: free RAM"); \
    message=("The available free RAM on " . $Identity . " is at " . $CheckHealthFreeRAM . "% (" . \
    ($Resource->"free-memory" / 1024 / 1024) . "MiB)!") });
  :set CheckHealthFreeRAMNotified true;
}
:if ($CheckHealthFreeRAM > 30 && $CheckHealthFreeRAMNotified = true) do={
  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "card-file-box,chart-increasing" ] . "Health recovery: free RAM"); \
    message=("The available free RAM on " . $Identity . " increased to " . $CheckHealthFreeRAM . "% (" . \
    ($Resource->"free-memory" / 1024 / 1024) . "MiB).") });
  :set CheckHealthFreeRAMNotified false;
}

:if ([ :len [ /system/health/find ] ] = 0) do={
  $LogPrintExit2 debug $0 ("Your device does not provide any health values.") true;
}

:if ([ :typeof $CheckHealthLast ] != "array") do={
  :set CheckHealthLast ({});
}
:if ([ :typeof $CheckHealthTemperatureNotified ] != "array") do={
  :set CheckHealthTemperatureNotified ({});
}


:foreach Voltage in=[ /system/health/find where type="V" ] do={
  :local Name  [ /system/health/get $Voltage name  ];
  :local Value [ /system/health/get $Voltage value ];

  :if ([ :typeof ($CheckHealthLast->$Name) ] != "nothing") do={
    :local NumCurr [ $TempToNum $Value ];
    :local NumLast [ $TempToNum ($CheckHealthLast->$Name) ];

    :if ($NumLast * (100 + $CheckHealthVoltagePercent) < $NumCurr * 100 || \
         $NumLast * 100 > $NumCurr * (100 + $CheckHealthVoltagePercent)) do={
      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification ("high-voltage-sign,chart-" . [ $IfThenElse ($NumLast < \
          $NumCurr) "in" "de" ] . "creasing") ] . "Health warning: " . $Name); \
        message=("The " . $Name . " on " . $Identity . " jumped more than " . $CheckHealthVoltagePercent . "%.\n\n" . \
          "old value: " . ($CheckHealthLast->$Name) . " V\n" . \
          "new value: " . $Value . " V") });
    } else={ 
      :if ($NumCurr <= $CheckHealthVoltageLow && $NumLast > $CheckHealthVoltageLow) do={ 
        $SendNotification2 ({ origin=$0; \ 
          subject=([ $SymbolForNotification "high-voltage-sign,chart-decreasing" ] . "Health warning: Low " . $Name); \ 
          message=("The " . $Name . " on " . $Identity . " dropped to " . $Value . " V below hard limit.") }); 
      } 
      :if ($NumCurr > $CheckHealthVoltageLow && $NumLast <= $CheckHealthVoltageLow) do={ 
        $SendNotification2 ({ origin=$0; \ 
          subject=([ $SymbolForNotification "high-voltage-sign,chart-increasing" ] . "Health recovery: Low " . $Name); \ 
          message=("The " . $Name . " on " . $Identity . " recovered to " . $Value . " V above hard limit.") }); 
      }
    }
  }
  :set ($CheckHealthLast->$Name) $Value;
}

:foreach PSU in=[ /system/health/find where name~"^psu.*-state\$" ] do={
  :local Name  [ /system/health/get $PSU name  ];
  :local Value [ /system/health/get $PSU value ];

  :if ([ :typeof ($CheckHealthLast->$Name) ] != "nothing") do={
    :if ($CheckHealthLast->$Name = "ok" && \
         $Value != "ok") do={
      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification "cross-mark" ] . "Health warning: " . $Name); \
        message=("The power supply unit '" . $Name . "' on " . $Identity . " failed!") });
    }
    :if ($CheckHealthLast->$Name != "ok" && \
         $Value = "ok") do={
      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification "white-heavy-check-mark" ] . "Health recovery: " . $Name); \
        message=("The power supply unit '" . $Name . "' on " . $Identity . " recovered!") });
    }
  }
  :set ($CheckHealthLast->$Name) $Value;
}

:foreach Temperature in=[ /system/health/find where type="C" ] do={
  :local Name  [ /system/health/get $Temperature name  ];
  :local Value [ /system/health/get $Temperature value ];

  :if ([ :typeof ($CheckHealthLast->$Name) ] != "nothing") do={
    :if ([ :typeof ($CheckHealthTemperature->$Name) ] != "num" ) do={
      $LogPrintExit2 info $0 ("No threshold given for " . $Name . ", assuming 50C.") false;
      :set ($CheckHealthTemperature->$Name) 50;
    }
    :local Validate [ /system/health/get [ find where name=$Name ] value ];
    :while ($Value != $Validate) do={
      :set Value $Validate;
      :set Validate [ /system/health/get [ find where name=$Name ] value ];
    }
    :if ($Value > $CheckHealthTemperature->$Name && \
         $CheckHealthTemperatureNotified->$Name != true) do={
      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification "fire" ] . "Health warning: " . $Name); \
        message=("The " . $Name . " on " . $Identity . " is above threshold: " . \
          $Value . "\C2\B0" . "C") });
      :set ($CheckHealthTemperatureNotified->$Name) true;
    }
    :if ($Value <= ($CheckHealthTemperature->$Name - $CheckHealthTemperatureDeviation) && \
         $CheckHealthTemperatureNotified->$Name = true) do={
      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification "white-heavy-check-mark" ] . "Health recovery: " . $Name); \
        message=("The " . $Name . " on " . $Identity . " dropped below threshold: " .  \
          $Value . "\C2\B0" . "C") });
      :set ($CheckHealthTemperatureNotified->$Name) false;
    }
  }
  :set ($CheckHealthLast->$Name) $Value;
}
