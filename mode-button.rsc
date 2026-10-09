#!rsc by RouterOS
# RouterOS script: mode-button
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, scheduler
# requires policy, dont-require-permissions
#
# act on multiple mode and reset button presses
# https://rsc.eworm.de/doc/mode-button.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=mode-button, schema=1b567608fb5b7d34f1710eac3a7c4e5740acbea43a5f928a6be5d5c6d189ed03
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"mode-button.scheduler.creating") "{script}: Creating scheduler mode-button-scheduler, counting presses...";
:set ($LanguageEnglish->"mode-button.scheduler.updating") "{script}: Updating scheduler mode-button-scheduler...";
# END GENERATED LANGUAGE DATA

# BEGIN GENERATED LOCAL LANGUAGE RENDERER
:local Translate do={
  :local Key [ :tostr $1 ];
  :local Params $2;
  :global ScriptLanguage;
  :global LanguageEnglish;
  :global LanguageMessages;
  :global LanguageActive;

  :local English ($LanguageEnglish->$Key);
  :if ([ :typeof $English ] != "str") do={ :return $Key; }
  :local Text $English;
  :if ($LanguageActive = $ScriptLanguage && [ :typeof ($LanguageMessages->$Key) ] = "str") do={
    :set Text ($LanguageMessages->$Key);
  }
  :local Tokens do={
    :local Text $1;
    :local Names ({});
    :while ([ :len $Text ] > 0) do={
      :local Start [ :find $Text "{" ];
      :if ([ :typeof $Start ] = "nil") do={
        :if ([ :typeof [ :find $Text "}" ] ] != "nil") do={ :return false; }
        :return $Names;
      }
      :local End [ :find $Text "}" $Start ];
      :if ([ :typeof $End ] = "nil") do={ :return false; }
      :if ([ :typeof [ :find [ :pick $Text 0 $Start ] "}" ] ] != "nil") do={ :return false; }
      :local Name [ :pick $Text ($Start + 1) $End ];
      :if (!($Name ~ "^[a-z][a-z0-9_]*\$")) do={ :return false; }
      :set ($Names->$Name) true;
      :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
    }
    :return $Names;
  }
  :local EnglishTokens [ $Tokens $English ];
  :local TranslatedTokens [ $Tokens $Text ];
  :local Valid false;
  :if ([ :typeof $TranslatedTokens ] = "array" && \
       [ :len $EnglishTokens ] = [ :len $TranslatedTokens ]) do={
    :set Valid true;
    :foreach Name,Unused in=$EnglishTokens do={
      :if (($TranslatedTokens->$Name) != true) do={ :set Valid false; }
    }
  }
  :if ($Valid != true) do={ :set Text $English; }
  :local Result "";
  :while ([ :len $Text ] > 0) do={
    :local Start [ :find $Text "{" ];
    :if ([ :typeof $Start ] = "nil") do={ :return ($Result . $Text); }
    :local End [ :find $Text "}" $Start ];
    :if ([ :typeof $End ] = "nil") do={ :return $English; }
    :local Name [ :pick $Text ($Start + 1) $End ];
    :if ([ :typeof ($Params->$Name) ] = "nothing" || \
         [ :typeof ($Params->$Name) ] = "nil") do={ :return $English; }
    :set Result ($Result . [ :pick $Text 0 $Start ] . [ :tostr ($Params->$Name) ]);
    :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
  }
  :return $Result;
}
# END GENERATED LOCAL LANGUAGE RENDERER

:onerror Err {
  :local ScriptName [ :jobname ];

  :local Scheduler [ /system/scheduler/find where name="mode-button-scheduler" ];

  :if ([ :len $Scheduler ] = 0) do={
    :log info [ $Translate "mode-button.scheduler.creating" \
        ({ script=$ScriptName }) ];
    /system/scheduler/add name="mode-button-scheduler" interval=3s \
        comment=[ :serialize to=json ({ count=1 }) ] \
        on-event="/system/script/run mode-button-scheduler;";
  } else={
    :log debug [ $Translate "mode-button.scheduler.updating" \
        ({ script=$ScriptName }) ];
    :local Presses (([ :deserialize from=json [ /system/scheduler/get $Scheduler comment ] ]->"count") + 1);
    /system/scheduler/set $Scheduler start-time=[ /system/clock/get time ] \
        comment=[ :serialize to=json ({ count=$Presses }) ];
  }
} do={
  :log error ([ :jobname ] . ": " . $Err);
}
