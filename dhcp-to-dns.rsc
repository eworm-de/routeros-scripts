#!rsc by RouterOS
# RouterOS script: dhcp-to-dns
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: lease-script, order=20
#
# check DHCP leases and add/remove/update DNS entries
# https://git.eworm.de/cgit/routeros-scripts/about/doc/dhcp-to-dns.md

:local 0 "dhcp-to-dns";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global Domain;
:global Identity;

:global CharacterReplace;
:global EitherOr;
:global IfThenElse;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0 false 10;

:local Ttl 5m;
:local CommentPrefix ("managed by " . $0 . " for ");
:local CommentString ("--- " . $0 . " above ---");

:if ([ :len [ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ] ] = 0) do={
  /ip/dns/static/add name=$CommentString type=NXDOMAIN disabled=yes;
  $LogPrintExit2 warning $0 ("Added disabled static dns record with name '" . $CommentString . "'.") false;
}
:local PlaceBefore ([ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ]->0);

:foreach DnsRecord in=[ /ip/dns/static/find where comment~("^" . $CommentPrefix) (!type or type=A or type=AAAA) ] do={
  :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
  :local MacAddrIface [ $CharacterReplace ($DnsRecordVal->"comment") $CommentPrefix "" ];
  :local MacAddress [ :pick $MacAddrIface 0 [ :find $MacAddrIface "%" ] ];
  :local Interface [ :pick $MacAddrIface ([ :find $MacAddrIface "%" ]+1) [ :len $MacAddrIface ] ];
  :local DHCPServerName [ /ip/dhcp-server/get [ find where interface=$Interface ] name ];

  :if ($DnsRecordVal->"type" != "AAAA") do={
    :if ([ :len [ /ip/dhcp-server/lease/find where active-mac-address=$MacAddress active-address=($DnsRecordVal->"address") server=$DHCPServerName status=bound ] ] > 0) do={
      $LogPrintExit2 debug $0 ("Lease for " . $MacAddrIface . " (" . $DnsRecordVal->"name" . ") still exists. Not deleting DNS entry.") false;
    } else={
      :local Found false;
      $LogPrintExit2 info $0 ("Lease expired for " . $MacAddrIface . " (" . $DnsRecordVal->"name" . "), deleting DNS entry.") false;
      /ip/dns/static/remove $DnsRecord;
      /ip/dns/static/remove [ find where type=CNAME comment=($DnsRecordVal->"comment") ];
    }
  } else={
    :if (([ :len [ /ip/dhcp-server/lease/find where active-mac-address=$MacAddress server=$DHCPServerName status=bound ] ] > 0) and ([ :len [ /ipv6/neighbor/find where mac-address=$MacAddress address=($DnsRecordVal->"address") interface=$Interface status!=failed ] ] > 0)) do={
      $LogPrintExit2 debug $0 ("Lease and IPv6 neighbor for " . $MacAddrIface . " (" . $DnsRecordVal->"name" . ") still exists. Not deleting AAAA DNS entry.") false;
    } else={
      :local Found false;
      $LogPrintExit2 info $0 ("Lease expired or IPv6 neighbor failed for " . $MacAddrIface . " (" . $DnsRecordVal->"name" . "), deleting AAAA DNS entry.") false;
      /ip/dns/static/remove $DnsRecord;
    }
  }
}

:foreach Lease in=[ /ip/dhcp-server/lease/find where status=bound ] do={
  :local LeaseVal;
  :do {
    :set LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
    :local DupMacLeases [ /ip/dhcp-server/lease/find where active-mac-address=($LeaseVal->"active-mac-address") server=($LeaseVal->"server") status=bound ];
    :if ([ :len $DupMacLeases ] > 1) do={
      $LogPrintExit2 debug $0 ("Multiple bound leases found for mac-address " . ($LeaseVal->"active-mac-address") . ", using last one.") false;
      :set LeaseVal [ /ip/dhcp-server/lease/get ($DupMacLeases->([ :len $DupMacLeases ] - 1)) ];
    }
  } on-error={
    $LogPrintExit2 debug $0 ("A lease just vanished, ignoring.") false;
  }

  :if ([ :len ($LeaseVal->"active-address") ] > 0) do={
    :local Interface ([ /ip/dhcp-server/get [ find where name=($LeaseVal->"server") ] ]->"interface");
    :local Comment ($CommentPrefix . $LeaseVal->"active-mac-address" . "%" . $Interface);
    :local MacDash [ $CharacterReplace ($LeaseVal->"active-mac-address") ":" "-" ];
    :local HostName [ $CharacterReplace [ $EitherOr ([ $ParseKeyValueStore ($LeaseVal->"comment") ]->"hostname") ($LeaseVal->"host-name") ] " " "" ];
    :local Network [ /ip/dhcp-server/network/find where ($LeaseVal->"active-address") in address ];
    :local NetworkVal;
    :if ([ :len $Network ] > 0) do={
      :set NetworkVal [ /ip/dhcp-server/network/get ($Network->0) ];
    }
    :local NetworkInfo [ $ParseKeyValueStore ($NetworkVal->"comment") ];
    :local NetDomain ([ $IfThenElse ([ :len ($NetworkInfo->"name-extra") ] > 0) ($NetworkInfo->"name-extra" . ".") ] . \
      [ $EitherOr [ $EitherOr ($NetworkInfo->"domain") ($NetworkVal->"domain") ] $Domain ]);

    :local DnsRecord [ /ip/dns/static/find where comment=$Comment (!type or type=A) ];
    :if ([ :len $DnsRecord ] > 0) do={
      :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];

      :if ($DnsRecordVal->"address" = $LeaseVal->"active-address" && $DnsRecordVal->"name" = ($MacDash . "." . $NetDomain)) do={
        $LogPrintExit2 debug $0 ("DNS entry for " . $LeaseVal->"active-mac-address" . " does not need updating.") false;
      } else={
        $LogPrintExit2 info $0 ("Replacing DNS entry for " . $LeaseVal->"active-mac-address" . " (" . ($MacDash . "." . $NetDomain) . " -> " . $LeaseVal->"active-address" . ").") false;
        /ip/dns/static/set address=($LeaseVal->"active-address") name=($MacDash . "." . $NetDomain) $DnsRecord;
      }

      :local Cname [ /ip/dns/static/find where comment=$Comment type=CNAME ];
      :if ([ :len $Cname ] = 0 && [ :len $HostName ] > 0) do={
        $LogPrintExit2 info $0 ("Host name appeared, adding CNAME (" . ($HostName . "." . $NetDomain) . " -> " . ($MacDash . "." . $NetDomain) . ").") false;
        /ip/dns/static/add name=($HostName . "." . $NetDomain) type=CNAME cname=($MacDash . "." . $NetDomain) ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
      :if ([ :len $Cname ] > 0 && [ /ip/dns/static/get $Cname name ] != ($HostName . "." . $NetDomain)) do={
        $LogPrintExit2 info $0 ("Host name or domain changed, updating CNAME (" . ($HostName . "." . $NetDomain) . " -> " . ($MacDash . "." . $NetDomain) . ").") false;
        /ip/dns/static/set name=($HostName . "." . $NetDomain) cname=($MacDash . "." . $NetDomain) $Cname;
      }
    } else={
      $LogPrintExit2 info $0 ("Adding new DNS entry for " . $LeaseVal->"active-mac-address" . " (" . ($MacDash . "." . $NetDomain) . " -> " . $LeaseVal->"active-address" . ").") false;
      /ip/dns/static/add name=($MacDash . "." . $NetDomain) type=A address=($LeaseVal->"active-address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      :if ([ :len $HostName ] > 0) do={
        $LogPrintExit2 info $0 ("Adding new CNAME (" . ($HostName . "." . $NetDomain) . " -> " . ($MacDash . "." . $NetDomain) . ").") false;
        /ip/dns/static/add name=($HostName . "." . $NetDomain) type=CNAME cname=($MacDash . "." . $NetDomain) ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
    }

    :local V6Neighbors [ /ipv6/neighbor/find where mac-address=($LeaseVal->"active-mac-address") interface=$Interface (((address & ffff::) ^ fe80::) != ::) status=reachable ];
    :if ([ :len $V6Neighbors ] > 0) do={
      :local V6Neighbor ($V6Neighbors->0);
      :local V6NeighborVal [ /ipv6/neighbor/get $V6Neighbor ];
      :local DnsRecord [ /ip/dns/static/find where comment=$Comment type=AAAA ];
      :if ([ :len $DnsRecord ] > 0) do={
        :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
        :if ($DnsRecordVal->"address" = $V6NeighborVal->"address" && $DnsRecordVal->"name" = ($MacDash . "." . $NetDomain)) do={
          $LogPrintExit2 debug $0 ("V6 DNS entry for " . $LeaseVal->"active-mac-address" . " does not need updating.") false;
        } else={
          $LogPrintExit2 info $0 ("Replacing V6 DNS entry for " . $LeaseVal->"active-mac-address" . " (" . ($MacDash . "." . $NetDomain) . " -> " . $V6NeighborVal->"address" . ").") false;
          /ip/dns/static/set address=($V6NeighborVal->"address") name=($MacDash . "." . $NetDomain) $DnsRecord;
        }
      } else={
        $LogPrintExit2 info $0 ("Adding new V6 DNS entry for " . $LeaseVal->"active-mac-address" . " (" . ($MacDash . "." . $NetDomain) . " -> " . $V6NeighborVal->"address" . ").") false;
        /ip/dns/static/add name=($MacDash . "." . $NetDomain) type=AAAA address=($V6NeighborVal->"address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
    }
  } else={
    $LogPrintExit2 debug $0 ("No address available... Ignoring.") false;
  }
}
