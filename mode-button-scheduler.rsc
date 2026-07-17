#!rsc by RouterOS
# RouterOS script: mode-button-scheduler
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.21
# requires device-mode, scheduler
#
# act on multiple mode and reset button presses
# https://rsc.eworm.de/doc/mode-button.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global ModeButton;

  :global LogPrint;
  :global ModeButtonScheduler;
  :global ValidateSyntax;

  :local LEDInvert do={
    :global ModeButtonLED;

    :global IfThenElse;

    :local LED [ /system/leds/find where leds=$ModeButtonLED \
        !disabled type~"^(on|off)\$" interface=[] ];
    :if ([ :len $LED ] = 0) do={
      :return false;
    }
    /system/leds/set type=[ $IfThenElse ([ get $LED type ] = "on") "off" "on" ] $LED;
  }

  :local Count ($ModeButton->"count");
  :local Code ($ModeButton->[ :tostr $Count ]);

  :set ($ModeButton->"count") 0;
  :set ModeButtonScheduler;
  /system/scheduler/remove [ find where name="mode-button-scheduler" ];

  :if ([ :len $Code ] = 0) do={
    $LogPrint info $ScriptName ("No action defined for " . $Count . " mode-button presses.");
    :set ExitOK true;
    :error false;
  }

  :if ([ $ValidateSyntax $Code ] = false) do={
    $LogPrint warning $ScriptName \
        ("The code for " . $Count . " mode-button presses failed syntax validation!");
    :set ExitOK true;
    :error false;
  }

  $LogPrint info $ScriptName ("Acting on " . $Count . " mode-button presses: " . $Code);

  :for I from=1 to=$Count do={
    $LEDInvert;
    :if ([ /system/routerboard/settings/get silent-boot ] = false) do={
      :beep length=200ms;
    }
    :delay 200ms;
    $LEDInvert;
    :delay 200ms;
  }

  :onerror Err {
    [ :parse $Code ];
  } do={
    $LogPrint warning $ScriptName \
        ("The code for " . $Count . " mode-button presses failed with runtime error: " . $Err);
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
