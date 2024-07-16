#!rsc by RouterOS
# RouterOS script: ipsec-to-dns
# Copyright (c) 2021-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.14
#
# and add/remove/update DNS entries from IPSec mode-config
# https://git.eworm.de/cgit/routeros-scripts/about/doc/ipsec-to-dns.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global Domain;
  :global HostNameInZone;
  :global Identity;
  :global PrefixInZone;

  :global CharacterReplace;
  :global EscapeForRegEx;
  :global IfThenElse;
  :global LogPrint;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :error false;
  }

  :local Zone \
    ([ $IfThenElse ($PrefixInZone = true) "ipsec." ] . \
     [ $IfThenElse ($HostNameInZone = true) ($Identity . ".") ] . $Domain);
  :local Ttl 5m;
  :local CommentPrefix ("managed by " . $ScriptName . " for ");
  :local CommentString ("--- " . $ScriptName . " above ---");

  :if ([ :len [ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ] ] = 0) do={
    /ip/dns/static/add name=$CommentString type=NXDOMAIN disabled=yes;
    $LogPrint warning $ScriptName ("Added disabled static dns record with name '" . $CommentString . "'.");
  }
  :local PlaceBefore ([ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ]->0);

  :foreach DnsRecord in=[ /ip/dns/static/find where comment~("^" . $CommentPrefix) ] do={
    :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
    :local PeerId [ $CharacterReplace ($DnsRecordVal->"comment") $CommentPrefix "" ];
    :if ([ :len [ /ip/ipsec/active-peers/find where id~("^(CN=)?" . [ $EscapeForRegEx $PeerId ] . "\$") \
         dynamic-address=($DnsRecordVal->"address") ] ] > 0) do={
      $LogPrint debug $ScriptName ("Peer " . $PeerId . " (" . $DnsRecordVal->"name" . ") still exists. Not deleting DNS entry.");
    } else={
      :local Found false;
      $LogPrint info $ScriptName ("Peer " . $PeerId . " (" . $DnsRecordVal->"name" . ") has gone, deleting DNS entry.");
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
        $LogPrint debug $ScriptName ("DNS entry for " . $Fqdn . " does not need updating.");
      } else={
        $LogPrint info $ScriptName ("Replacing DNS entry for " . $Fqdn . ", new address is " . $PeerVal->"dynamic-address" . ".");
        /ip/dns/static/set name=$Fqdn address=($PeerVal->"dynamic-address") ttl=$Ttl comment=$Comment $DnsRecord;
      }
    } else={
      $LogPrint info $ScriptName ("Adding new DNS entry for " . $Fqdn . ", address is " . $PeerVal->"dynamic-address" . ".");
      /ip/dns/static/add name=$Fqdn address=($PeerVal->"dynamic-address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
    }
  }
} on-error={ }
