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
:global HostNameInZone;
:global Identity;
:global PrefixInZone;
:global ServerNameInZone;

:global CharacterReplace;
:global EitherOr;
:global IfThenElse;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0 false 10;

:local Zone \
  ([ $IfThenElse ($PrefixInZone = true) "dhcp." ] . \
   [ $IfThenElse ($HostNameInZone = true) ($Identity . ".") ] . $Domain);
:local Ttl 5m;
:local CommentPrefix ("managed by " . $0 . " for ");
:local CommentString ("--- " . $0 . " above ---");

:if ([ :len [ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ] ] = 0) do={
  /ip/dns/static/add name=$CommentString type=NXDOMAIN disabled=yes;
  $LogPrintExit2 warning $0 ("Added disabled static dns record with name '" . $CommentString . "'.") false;
}
:local PlaceBefore ([ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ]->0);

:foreach DnsRecord in=[ /ip/dns/static/find where comment~("^" . $CommentPrefix) (!type or type=A) ] do={
  :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
  :local MacAddress [ $CharacterReplace ($DnsRecordVal->"comment") $CommentPrefix "" ];
  :if ([ :len [ /ip/dhcp-server/lease/find where mac-address=$MacAddress address=($DnsRecordVal->"address") status=bound ] ] > 0) do={
    $LogPrintExit2 debug $0 ("Lease for " . $MacAddress . " (" . $DnsRecordVal->"name" . ") still exists. Not deleting DNS entry.") false;
  } else={
    :local Found false;
    $LogPrintExit2 info $0 ("Lease expired for " . $MacAddress . " (" . $DnsRecordVal->"name" . "), deleting DNS entry.") false;
    /ip/dns/static/remove $DnsRecord;
    /ip/dns/static/remove [ find where type=CNAME cname=($DnsRecordVal->"name") comment=($DnsRecordVal->"comment") ];
  }
}

:foreach Lease in=[ /ip/dhcp-server/lease/find where status=bound ] do={
  :local LeaseVal;
  :do {
    :set LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
  } on-error={
    $LogPrintExit2 debug $0 ("A lease just vanished, ignoring.") false;
  }

  :if ([ :len ($LeaseVal->"address") ] > 0) do={
    :local Comment ($CommentPrefix . $LeaseVal->"mac-address");
    :local MacDash [ $CharacterReplace ($LeaseVal->"mac-address") ":" "-" ];
    :local HostName [ $CharacterReplace [ $EitherOr ([ $ParseKeyValueStore ($LeaseVal->"comment") ]->"hostname") ($LeaseVal->"host-name") ] " " "" ];
    :local Domain ([ $IfThenElse ($ServerNameInZone = true) ($LeaseVal->"server" . ".") ] . $Zone);

    :local DnsRecord [ /ip/dns/static/find where name=($MacDash . "." . $Domain) ];
    :if ([ :len $DnsRecord ] > 0) do={
      :local DnsIp [ /ip/dns/static/get $DnsRecord address ];

      :local DupMacLeases [ /ip/dhcp-server/lease/find where mac-address=($LeaseVal->"mac-address") status=bound ];
      :if ([ :len $DupMacLeases ] > 1) do={
        $LogPrintExit2 debug $0 ("Multiple bound leases found for mac-address " . ($LeaseVal->"mac-address") . ", using ip address of last one.") false;
        :set ($LeaseVal->"address") [ /ip/dhcp-server/lease/get ($DupMacLeases->([ :len $DupMacLeases ] - 1)) address ];
      }

      :if ($DnsIp = $LeaseVal->"address") do={
        $LogPrintExit2 debug $0 ("DNS entry for " . ($MacDash . "." . $Domain) . " does not need updating.") false;
      } else={
        $LogPrintExit2 info $0 ("Replacing DNS entry for " . ($MacDash . "." . $Domain) . ", new address is " . $LeaseVal->"address" . ".") false;
        /ip/dns/static/set address=($LeaseVal->"address") $DnsRecord;
      }

      :local Cname [ /ip/dns/static/find where type=CNAME cname=($MacDash . "." . $Domain) comment=$Comment ];
      :if ([ :len $Cname ] = 0 && [ :len $HostName ] > 0) do={
        $LogPrintExit2 info $0 ("Host name appeared, adding CNAME " . ($HostName . "." . $Domain) . " pointing to " . ($MacDash . "." . $Domain) . ".") false;
        /ip/dns/static/add name=($HostName . "." . $Domain) type=CNAME cname=($MacDash . "." . $Domain) ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
      :if ([ :len $Cname ] > 0 && [ /ip/dns/static/get $Cname name ] != ($HostName . "." . $Domain)) do={
        $LogPrintExit2 info $0 ("Host name changed, updating CNAME (pointing to " . ($MacDash . "." . $Domain) . ") to " . ($HostName . "." . $Domain) . ".") false;
        /ip/dns/static/set name=($HostName . "." . $Domain) $Cname;
      }
    } else={
      $LogPrintExit2 info $0 ("Adding new DNS entry for " . ($MacDash . "." . $Domain) . ", address is " . $LeaseVal->"address" . ".") false;
      /ip/dns/static/add name=($MacDash . "." . $Domain) type=A address=($LeaseVal->"address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      :if ([ :len $HostName ] > 0) do={
        /ip/dns/static/add name=($HostName . "." . $Domain) type=CNAME cname=($MacDash . "." . $Domain) ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
    }
  } else={
    $LogPrintExit2 debug $0 ("No address available... Ignoring.") false;
  }
}
