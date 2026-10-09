#!rsc by RouterOS
# RouterOS script: accesslist-duplicates%TEMPL%
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# print duplicate antries in wireless access list
# https://rsc.eworm.de/doc/accesslist-duplicates.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

# BEGIN GENERATED LANGUAGE DATA
# language, name=accesslist-duplicates, schema=11c6e77afe0e5ea39b260eb21e4693aeb7b69299435563d0469b3c22651fdc8c
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"accesslist-duplicates.remove.prompt") "\0ANumeric id to remove, any key to skip!";
:set ($LanguageEnglish->"accesslist-duplicates.removing") "Removing numeric id {id}...\0A";
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

  :global Translate;

  :local Seen ({});

  :foreach AccList in=[ /caps-man/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
  :foreach AccList in=[ /interface/wifi/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
  :foreach AccList in=[ /interface/wireless/access-list/find where mac-address!="00:00:00:00:00:00" ] do={
    :local Mac [ /caps-man/access-list/get $AccList mac-address ];
    :local Mac [ /interface/wifi/access-list/get $AccList mac-address ];
    :local Mac [ /interface/wireless/access-list/get $AccList mac-address ];
    :if ($Seen->$Mac = 1) do={
      /caps-man/access-list/print without-paging where mac-address=$Mac;
      /interface/wifi/access-list/print without-paging where mac-address=$Mac;
      /interface/wireless/access-list/print without-paging where mac-address=$Mac;
      :local Remove [ :tonum [ /terminal/ask prompt=[ $Translate "accesslist-duplicates.remove.prompt" ] ] ];

      :if ([ :typeof $Remove ] = "num") do={
        :put [ $Translate "accesslist-duplicates.removing" \
            ({ id=$Remove }) ];
        /caps-man/access-list/remove $Remove;
        /interface/wifi/access-list/remove $Remove;
        /interface/wireless/access-list/remove $Remove;
      }
    }
    :set ($Seen->$Mac) 1;
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
