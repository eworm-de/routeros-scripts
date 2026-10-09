#!rsc by RouterOS
# RouterOS script: hotspot-to-wpa%TEMPL%
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, hotspot
# requires policy, policy=read;write
#
# add private WPA passphrase after hotspot login
# https://rsc.eworm.de/doc/hotspot-to-wpa.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

# BEGIN GENERATED LANGUAGE DATA
# language, name=hotspot-to-wpa, schema=82d921421b5113cc10cc742bba242aca700d0a06c7bba7435e2d6ce8faa20f74
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"hotspot-to-wpa.ignored") "{script}: Ignoring login for {mac} on hotspot '{hotspot}'.";
:set ($LanguageEnglish->"hotspot-to-wpa.lease.missing") "{script}: Did not find exactly one lease for {mac}!";
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

  :local Address $"address";
  :local Interface $"interface";
  :local MacAddress $"mac-address";
  :local UserName $"username";

  :local Hotspot [ /ip/hotspot/host/get [ find where mac-address=$MacAddress authorized ] server ];
  :if ([ :len [ /caps-man/access-list/find where \
  :if ([ :len [ /interface/wifi/access-list/find where \
       comment=("hotspot-to-wpa template " . $Hotspot) disabled action="reject" ] ] > 0) do={
    :log info [ $Translate "hotspot-to-wpa.ignored" \
        ({ script=$ScriptName; mac=$MacAddress; hotspot=$Hotspot }) ];
    :exit;
  }

  :local Lease [ /ip/dhcp-server/lease/find where mac-address=$MacAddress address=$Address ];
  :if ([ :len $Lease ] != 1) do={
    :log warning [ $Translate "hotspot-to-wpa.lease.missing" \
        ({ script=$ScriptName; mac=$MacAddress }) ];
    :exit;
  }

  /ip/dhcp-server/lease/set \
    comment=[ :serialize to=json ({ \
      "hotspot-to-wpa"=true; \
      "hotspot"=$Hotspot; \
      "address"=$Address; \
      "interface"=$Interface; \
      "mac-address"=$MacAddress; \
      "username"=$UserName }) ] $Lease;
  /ip/dhcp-server/lease/make-static $Lease;
  :delay 1s;
  /ip/dhcp-server/lease/disable $Lease;
} do={
  :log error ([ :jobname ] . ": " . $Err);
}
