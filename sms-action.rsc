#!rsc by RouterOS
# RouterOS script: sms-action
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# run action on received SMS
# https://rsc.eworm.de/doc/sms-action.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=sms-action, schema=91ff5010d0d869687a0bb1c0989668afd4c77fed76f0d8728bca83f00940d48e
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"sms-action.context") "This script is supposed to run from SMS hook with action=...";
:set ($LanguageEnglish->"sms-action.running") "Acting on SMS action '{action}': {code}";
:set ($LanguageEnglish->"sms-action.syntax") "The code for action '{action}' failed syntax validation!";
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

  :global SmsAction;

  :global LogPrint;
  :global Translate;
  :global ValidateSyntax;

  :local Action $action;

  :if ([ :typeof $Action ] = "nothing") do={
    $LogPrint error $ScriptName [ $Translate "sms-action.context" ];
    :exit;
  }

  :local Code ($SmsAction->$Action);
  :if ([ $ValidateSyntax $Code ] = true) do={
    :log info [ $Translate "sms-action.running" ({ action=$Action; code=$Code }) ];
    :delay 1s;
    [ :parse $Code ];
  } else={
    $LogPrint warning $ScriptName [ $Translate "sms-action.syntax" ({ action=$Action }) ];
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
