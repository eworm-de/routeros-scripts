#!rsc by RouterOS
# RouterOS script: mode-button
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
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

  :set ($ModeButton->"count") ($ModeButton->"count" + 1);

  :local Scheduler [ /system/scheduler/find where name="_ModeButtonScheduler" ];

  :if ([ :len $Scheduler ] = 0) do={
    $LogPrint info $ScriptName ("Creating scheduler _ModeButtonScheduler, counting presses...");
    :global ModeButtonScheduler do={ :onerror Err {
      :local FuncName $0;

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
      /system/scheduler/remove [ find where name="_ModeButtonScheduler" ];

      :if ([ :len $Code ] > 0) do={
        :if ([ $ValidateSyntax $Code ] = true) do={
          $LogPrint info $FuncName ("Acting on " . $Count . " mode-button presses: " . $Code);

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
            $LogPrint warning $FuncName \
                ("The code for " . $Count . " mode-button presses failed with runtime error: " . $Err);
          }
        } else={
          $LogPrint warning $FuncName \
              ("The code for " . $Count . " mode-button presses failed syntax validation!");
        }
      } else={
        $LogPrint info $FuncName ("No action defined for " . $Count . " mode-button presses.");
      }
    } do={
      :global ExitError; $ExitError false $0 $Err;
    } }
    /system/scheduler/add name="_ModeButtonScheduler" \
        on-event=":global ModeButtonScheduler; \$ModeButtonScheduler;" interval=3s;
  } else={
    $LogPrint debug $ScriptName ("Updating scheduler _ModeButtonScheduler...");
    /system/scheduler/set $Scheduler start-time=[ /system/clock/get time ];
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
