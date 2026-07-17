#!rsc by RouterOS
# RouterOS script: mode-button
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.21
# requires device-mode, scheduler
#
# act on multiple mode and reset button presses
# https://rsc.eworm.de/doc/mode-button.md

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global LogPrint;

  :local Scheduler [ /system/scheduler/find where name="mode-button-scheduler" ];

  :if ([ :len $Scheduler ] = 0) do={
    $LogPrint info $ScriptName ("Creating scheduler mode-button-scheduler, counting presses...");
    /system/scheduler/add name="mode-button-scheduler" interval=3s \
        comment=[ :serialize to=json ({ count=1 }) ] \
        on-event="/system/script/run mode-button-scheduler;";
  } else={
    $LogPrint debug $ScriptName ("Updating scheduler mode-button-scheduler...");
    :local Presses (([ :deserialize from=json [ /system/scheduler/get $Scheduler comment ] ]->"count") + 1);
    /system/scheduler/set $Scheduler start-time=[ /system/clock/get time ] \
        comment=[ :serialize to=json ({ count=$Presses }) ];
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
