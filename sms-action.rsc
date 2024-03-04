#!rsc by RouterOS
# RouterOS script: sms-action
# Copyright (c) 2018-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.12
#
# run action on received SMS
# https://git.eworm.de/cgit/routeros-scripts/about/doc/sms-action.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local Main do={
  :local ScriptName [ :tostr $1 ];
  :local Action     [ :tostr $2 ];

  :global SmsAction;

  :global LogPrintExit2;
  :global ValidateSyntax;

  :if ([ :len $Action ] = 0) do={
    $LogPrintExit2 error $ScriptName ("This script is supposed to run from SMS hook with action=...") true;
  }

  :local Code ($SmsAction->$Action);
  :if ([ $ValidateSyntax $Code ] = true) do={
    :log info ("Acting on SMS action '" . $Action . "': " . $Code);
    :delay 1s;
    [ :parse $Code ];
  } else={
    $LogPrintExit2 warning $ScriptName ("The code for action '" . $Action . "' failed syntax validation!") false;
  }
}

$Main [ :jobname ] $action;
