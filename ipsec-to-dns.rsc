#!rsc by RouterOS
# RouterOS script: ipsec-to-dns
# Copyright (c) 2021-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, ipsec
#
# and add/remove/update DNS entries from IPSec mode-config
# https://rsc.eworm.de/doc/ipsec-to-dns.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=ipsec-to-dns, schema=ed1c281155d118ad0f626106c929affb97ffffbf416dd87053f0becd389012dc
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"ipsec-to-dns.adding") "Adding new DNS entry for {name}, address is {address}.";
:set ($LanguageEnglish->"ipsec-to-dns.current") "DNS entry for {name} does not need updating.";
:set ($LanguageEnglish->"ipsec-to-dns.marker.added") "Added disabled static dns record with name '{name}'.";
:set ($LanguageEnglish->"ipsec-to-dns.peer.exists") "Peer {peer} ({name}) still exists. Not deleting DNS entry.";
:set ($LanguageEnglish->"ipsec-to-dns.peer.gone") "Peer {peer} ({name}) has gone, deleting DNS entry.";
:set ($LanguageEnglish->"ipsec-to-dns.replacing") "Replacing DNS entry for {name}, new address is {address}.";
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

  :global Domain;
  :global HostNameInZone;
  :global Identity;
  :global PrefixInZone;

  :global CharacterReplace;
  :global EscapeForRegEx;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :local Zone \
    ([ $IfThenElse ($PrefixInZone = true) "ipsec." ] . \
     [ $IfThenElse ($HostNameInZone = true) ($Identity . ".") ] . $Domain);
  :local Ttl 5m;
  :local CommentPrefix ("managed by " . $ScriptName . " for ");
  :local CommentString ("--- " . $ScriptName . " above ---");

  :if ([ :len [ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ] ] = 0) do={
    /ip/dns/static/add name=$CommentString type=NXDOMAIN disabled=yes;
    $LogPrint warning $ScriptName [ $Translate "ipsec-to-dns.marker.added" \
        ({ name=$CommentString }) ];
  }
  :local PlaceBefore ([ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ]->0);

  :foreach DnsRecord in=[ /ip/dns/static/find where comment~("^" . $CommentPrefix) ] do={
    :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
    :local PeerId [ $CharacterReplace ($DnsRecordVal->"comment") $CommentPrefix "" ];
    :if ([ :len [ /ip/ipsec/active-peers/find where id~("^(CN=)?" . [ $EscapeForRegEx $PeerId ] . "\$") \
         dynamic-address=($DnsRecordVal->"address") ] ] > 0) do={
      $LogPrint debug $ScriptName [ $Translate "ipsec-to-dns.peer.exists" \
          ({ peer=$PeerId; name=($DnsRecordVal->"name") }) ];
    } else={
      :local Found false;
      $LogPrint info $ScriptName [ $Translate "ipsec-to-dns.peer.gone" \
          ({ peer=$PeerId; name=($DnsRecordVal->"name") }) ];
      /ip/dns/static/remove $DnsRecord;
    }
  }

  :foreach Peer in=[ /ip/ipsec/active-peers/find where !(dynamic-address=[]) ] do={
    :local PeerVal [ /ip/ipsec/active-peers/get $Peer ];
    :local PeerId [ $CharacterReplace ($PeerVal->"id") "CN=" "" ];
    :local Comment ($CommentPrefix . $PeerId);
    :local HostName [ :pick $PeerId 0 [ :find ($PeerId . ".") "." ] ];

    :local Fqdn ($HostName . "." . $Zone);
    :local DnsRecord [ /ip/dns/static/find where name=$Fqdn ];
    :if ([ :len $DnsRecord ] > 0) do={
      :local DnsIp [ /ip/dns/static/get $DnsRecord address ];
      :if ($DnsIp = $PeerVal->"dynamic-address") do={
        $LogPrint debug $ScriptName [ $Translate "ipsec-to-dns.current" \
            ({ name=$Fqdn }) ];
      } else={
        $LogPrint info $ScriptName [ $Translate "ipsec-to-dns.replacing" \
            ({ name=$Fqdn; address=($PeerVal->"dynamic-address") }) ];
        /ip/dns/static/set name=$Fqdn address=($PeerVal->"dynamic-address") ttl=$Ttl comment=$Comment $DnsRecord;
      }
    } else={
      $LogPrint info $ScriptName [ $Translate "ipsec-to-dns.adding" \
          ({ name=$Fqdn; address=($PeerVal->"dynamic-address") }) ];
      /ip/dns/static/add name=$Fqdn address=($PeerVal->"dynamic-address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
