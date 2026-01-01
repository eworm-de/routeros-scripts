#!rsc by RouterOS
# RouterOS script: sms-action
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# run action on received SMS
# https://rsc.eworm.de/doc/sms-action.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global SmsAction;

  :global LogPrint;
  :global ValidateSyntax;

  :local Action $action;

  :if ([ :typeof $Action ] = "nothing") do={
    $LogPrint error $ScriptName ("This script is supposed to run from SMS hook with action=...");
    :set ExitOK true;
    :error false;
  }

  :local Code ($SmsAction->$Action);
  :if ([ $ValidateSyntax $Code ] = true) do={
    :log info ("Acting on SMS action '" . $Action . "': " . $Code);
    :delay 1s;
    [ :parse $Code ];
  } else={
    $LogPrint warning $ScriptName ("The code for action '" . $Action . "' failed syntax validation!");
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
