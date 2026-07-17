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

  :global ModeButton;

  :global LogPrint;

  :set ($ModeButton->"count") ($ModeButton->"count" + 1);

  :local Scheduler [ /system/scheduler/find where name="mode-button-scheduler" ];

  :if ([ :len $Scheduler ] = 0) do={
    $LogPrint info $ScriptName ("Creating scheduler mode-button-scheduler, counting presses...");
    /system/scheduler/add name="mode-button-scheduler" interval=3s \
        on-event="/system/script/run mode-button-scheduler;";
  } else={
    $LogPrint debug $ScriptName ("Updating scheduler mode-button-scheduler...");
    /system/scheduler/set $Scheduler start-time=[ /system/clock/get time ];
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
