#!rsc by RouterOS
# RouterOS script: mode-button-scheduler
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, scheduler
#
# act on multiple mode and reset button presses
# https://rsc.eworm.de/doc/mode-button.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=mode-button-scheduler, schema=573b86779a15979155d7ff480e677e88dbe77a77cbd92ffaba77887856e8af91
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"mode-button-scheduler.acting") "Acting on {count} mode-button presses: {code}";
:set ($LanguageEnglish->"mode-button-scheduler.action.missing") "No action defined for {count} mode-button presses.";
:set ($LanguageEnglish->"mode-button-scheduler.failed") "The code for {count} mode-button presses failed with runtime error: {error}";
:set ($LanguageEnglish->"mode-button-scheduler.scheduler.missing") "Scheduler does not exist.";
:set ($LanguageEnglish->"mode-button-scheduler.syntax") "The code for {count} mode-button presses failed syntax validation!";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :global GlobalNotReadyMessage;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error $GlobalNotReadyMessage; }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global ModeButton;

  :global LogPrint;
  :global Translate;
  :global ModeButtonScheduler;
  :global ValidateSyntax;

  :local LEDInvert do={
    :global ModeButtonLED;

    :global IfThenElse;

    :local LED [ /system/leds/find where leds=$ModeButtonLED \
        !disabled (type="on" or type="off") !interface ];
    :if ([ :len $LED ] = 0) do={
      :return false;
    }
    /system/leds/set type=[ $IfThenElse ([ get $LED type ] = "on") "off" "on" ] $LED;
  }

  :local Scheduler [ /system/scheduler/find where name="mode-button-scheduler" ];

  :if ([ :len $Scheduler ] = 0) do={
    $LogPrint error $ScriptName [ $Translate "mode-button-scheduler.scheduler.missing" ];
    :exit;
  }
  
  :local Count ([ :deserialize from=json [ /system/scheduler/get $Scheduler comment ] ]->"count");
  :local Code ($ModeButton->[ :tostr $Count ]);

  /system/scheduler/remove $Scheduler;

  :if ([ :len $Code ] = 0) do={
    $LogPrint info $ScriptName [ $Translate "mode-button-scheduler.action.missing" \
        ({ count=$Count }) ];
    :exit;
  }

  :if ([ $ValidateSyntax $Code ] = false) do={
    $LogPrint warning $ScriptName \
        [ $Translate "mode-button-scheduler.syntax" \
            ({ count=$Count }) ];
    :exit;
  }

  $LogPrint info $ScriptName [ $Translate "mode-button-scheduler.acting" \
      ({ count=$Count; code=$Code }) ];

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
        [ $Translate "mode-button-scheduler.failed" \
            ({ count=$Count; error=$Err }) ];
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
