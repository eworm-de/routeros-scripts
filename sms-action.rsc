#!rsc by RouterOS
# RouterOS script: sms-action
# Copyright (c) 2018-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.14
#
# run action on received SMS
# https://git.eworm.de/cgit/routeros-scripts/about/doc/sms-action.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global SmsAction;

  :global LogPrint;
  :global ValidateSyntax;

  :local Action $action;

  :if ([ :typeof $Action ] = "nothing") do={
    $LogPrint error $ScriptName ("This script is supposed to run from SMS hook with action=...");
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
} on-error={ }
