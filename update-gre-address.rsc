#!rsc by RouterOS
# RouterOS script: update-gre-address
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# update gre interface remote address with dynamic address from
# ipsec remote peer
# https://rsc.eworm.de/doc/update-gre-address.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=update-gre-address, schema=0e2b08c61a2482826cdb76bf0519f2a4e13db3e71eb3bb4644023ef8e6cb4c86
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"update-gre-address.updating") "Updating remote address for interface {interface} to {address}";
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

  :global CharacterReplace;
  :global LogPrint;
  :global Translate;
  :global ScriptLock; 

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  /interface/gre/set remote-address=0.0.0.0 disabled=yes [ find where !running !disabled ];

  :foreach Peer in=[ /ip/ipsec/active-peers/find ] do={
    :local PeerVal [ /ip/ipsec/active-peers/get $Peer ];
    :local GreInt [ /interface/gre/find where comment=($PeerVal->"id") or comment=[ $CharacterReplace ($PeerVal->"id") "CN=" "" ] ];
    :if ([ :len $GreInt ] > 0) do={
      :local GreIntVal [ /interface/gre/get $GreInt ];
      :if ([ :typeof ($PeerVal->"dynamic-address") ] = "str" && \
           ($PeerVal->"dynamic-address" != $GreIntVal->"remote-address" || \
            $GreIntVal->"disabled" = true)) do={
        $LogPrint info $ScriptName [ $Translate "update-gre-address.updating" \
            ({ interface=($GreIntVal->"name"); address=($PeerVal->"dynamic-address") }) ];
        /interface/gre/set remote-address=0.0.0.0 disabled=yes [ find where remote-address=$PeerVal->"dynamic-address" name!=$GreIntVal->"name" ];
        /interface/gre/set $GreInt remote-address=($PeerVal->"dynamic-address") disabled=no;
      }
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
