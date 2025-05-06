#!rsc by RouterOS
# RouterOS script: update-gre-address
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# update gre interface remote address with dynamic address from
# ipsec remote peer
# https://rsc.eworm.de/doc/update-gre-address.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local ExitOK false;
:onerror Err {
  :local ScriptName [ :jobname ];

  :global CharacterReplace;
  :global LogPrint;
  :global ScriptLock; 

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
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
        $LogPrint info $ScriptName ("Updating remote address for interface " . $GreIntVal->"name" . " to " . $PeerVal->"dynamic-address");
        /interface/gre/set remote-address=0.0.0.0 disabled=yes [ find where remote-address=$PeerVal->"dynamic-address" name!=$GreIntVal->"name" ];
        /interface/gre/set $GreInt remote-address=($PeerVal->"dynamic-address") disabled=no;
      }
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
