#!rsc by RouterOS
# RouterOS script: check-health.d/state
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# check for RouterOS health state - state plugin
# https://rsc.eworm.de/doc/check-health.md

:global CheckHealthPlugins;

:set ($CheckHealthPlugins->[ :jobname ]) do={
  :local FuncName   [ :tostr $0 ];
  :local ScriptName [ :tostr $1 ];

  :global CheckHealthLast;
  :global Identity;

  :global Translate;
  :global LogPrint;
  :global SendNotification2;
  :global SymbolForNotification;

  :if ([ :len [ /system/health/find where type="" name~"-state\$"] ] = 0) do={
    $LogPrint debug $FuncName ([ $Translate "check-health.state.unavailable" ]);
    :return false;
  }

  :foreach State in=[ /system/health/find where type="" name~"-state\$" ] do={
    :local Name  [ /system/health/get $State name  ];
    :local Value [ /system/health/get $State value ];

    :if ([ :typeof ($CheckHealthLast->$Name) ] != "nothing") do={
      :if ($CheckHealthLast->$Name = "ok" && \
           $Value != "ok") do={
        $SendNotification2 ({ origin=$ScriptName; \
          subject=([ $SymbolForNotification "cross-mark" ] . [ $Translate "check-health.warning.subject" ({ name=$Name }) ]); \
          message=([ $Translate "check-health.state.failed" ({ name=$Name; identity=$Identity }) ]) });
      }
      :if ($CheckHealthLast->$Name != "ok" && \
           $Value = "ok") do={
        $SendNotification2 ({ origin=$ScriptName; \
          subject=([ $SymbolForNotification "white-heavy-check-mark" ] . [ $Translate "check-health.recovery.subject" ({ name=$Name }) ]); \
          message=([ $Translate "check-health.state.recovered" ({ name=$Name; identity=$Identity }) ]) });
      }
    }
    :set ($CheckHealthLast->$Name) $Value;
  }
}
