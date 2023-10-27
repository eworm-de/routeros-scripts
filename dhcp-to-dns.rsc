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
:global LogPrintOnce;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0 false 10;

:local Ttl 5m;
:local CommentPrefix ("managed by " . $0);
:local CommentString ("--- " . $0 . " above ---");

:if ([ :len [ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ] ] = 0) do={
  /ip/dns/static/add name=$CommentString type=NXDOMAIN disabled=yes;
  $LogPrintExit2 warning $0 ("Added disabled static dns record with name '" . $CommentString . "'.") false;
}
:local PlaceBefore ([ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ]->0);

:foreach DnsRecord in=[ /ip/dns/static/find where comment~("^" . $CommentPrefix . "\\b") (!type or type=A) ] do={
  :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
  :local DnsRecordInfo [ $ParseKeyValueStore ($DnsRecordVal->"comment") ];
  :if ([ :len [ /ip/dhcp-server/lease/find where active-mac-address=($DnsRecordInfo->"macaddress") \
       active-address=($DnsRecordVal->"address") server=($DnsRecordInfo->"server") status=bound ] ] > 0) do={
    $LogPrintExit2 debug $0 ("Lease for " . $DnsRecordInfo->"macaddress" . " (" . $DnsRecordVal->"name" . ") still exists. Not deleting record.") false;
  } else={
    :local Found false;
    $LogPrintExit2 info $0 ("Lease expired for " . $DnsRecordInfo->"macaddress" . " in " . \
      $DnsRecordInfo->"server" . ", deleting record (" . $DnsRecordVal->"name" . ").") false;
    /ip/dns/static/remove $DnsRecord;
    /ip/dns/static/remove [ find where type=CNAME comment=($DnsRecordVal->"comment") ];
  }
}

:foreach Lease in=[ /ip/dhcp-server/lease/find where status=bound ] do={
  :local LeaseVal;
  :do {
    :set LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
    :if ([ :len [ /ip/dhcp-server/lease/find where active-mac-address=($LeaseVal->"active-mac-address") status=bound ] ] > 1) do={
      $LogPrintOnce info $0 ("Multiple bound leases found for mac-address " . ($LeaseVal->"active-mac-address") . "!");
    }
  } on-error={
    $LogPrintExit2 debug $0 ("A lease just vanished, ignoring.") false;
  }

  :if ([ :len ($LeaseVal->"active-address") ] > 0) do={
    :local Comment ($CommentPrefix . ", macaddress=" . $LeaseVal->"active-mac-address" . ", server=" . $LeaseVal->"server");
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
    :local FullA ($MacDash . "." . $NetDomain);
    :local FullCN ($HostName . "." . $NetDomain);

    :local DnsRecord [ /ip/dns/static/find where comment=$Comment (!type or type=A) ];
    :if ([ :len $DnsRecord ] > 0) do={
      :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];

      :if ($DnsRecordVal->"address" = $LeaseVal->"active-address" && $DnsRecordVal->"name" = $FullA) do={
        $LogPrintExit2 debug $0 ("The A record for " . $LeaseVal->"active-mac-address" . " in " . \
          $LeaseVal->"server" . " does not need updating.") false;
      } else={
        $LogPrintExit2 info $0 ("Updating A record for " . $LeaseVal->"active-mac-address" . " in " . \
          $LeaseVal->"server" . " (" . $FullA . " -> " . $LeaseVal->"active-address" . ").") false;
        /ip/dns/static/set address=($LeaseVal->"active-address") name=$FullA $DnsRecord;
      }

      :local CName [ /ip/dns/static/find where comment=$Comment type=CNAME ];
      :if ([ :len $CName ] > 0) do={
        :local CNameVal [ /ip/dns/static/get $CName ];
        :if ($CNameVal->"name" != $FullCN || $CNameVal->"cname" != $FullA) do={
          $LogPrintExit2 info $0 ("Deleting CNAME record with wrong data for " . $LeaseVal->"active-mac-address" . " in " . \
            $LeaseVal->"server" . ".") false;
          /ip/dns/static/remove $CName;
        }
      }
      :if ([ :len $HostName ] > 0 && [ :len [ /ip/dns/static/find where name=$FullCN type=CNAME ] ] = 0) do={
        $LogPrintExit2 info $0 ("Adding CNAME record for " . $LeaseVal->"active-mac-address" . " in " . \
          $LeaseVal->"server" . " (" . $FullCN . " -> " . $FullA . ").") false;
        /ip/dns/static/add name=$FullCN type=CNAME cname=$FullA ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }

    } else={
      $LogPrintExit2 info $0 ("Adding A record for " . $LeaseVal->"active-mac-address" . " in " . \
        $LeaseVal->"server" . " (" . $FullA . " -> " . $LeaseVal->"active-address" . ").") false;
      /ip/dns/static/add name=$FullA type=A address=($LeaseVal->"active-address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      :if ([ :len $HostName ] > 0 && [ :len [ /ip/dns/static/find where name=$FullCN type=CNAME ] ] = 0) do={
        $LogPrintExit2 info $0 ("Adding CNAME record for " . $LeaseVal->"active-mac-address" . " in " . \
          $LeaseVal->"server" . " (" . $FullCN . " -> " . $FullA . ").") false;
        /ip/dns/static/add name=$FullCN type=CNAME cname=$FullA ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
    }

    :if ([ :len [ /ip/dns/static/find where name=$FullA (!type or type=A) ] ] > 1) do={
      $LogPrintOnce warning $0 ("The name '" . $FullA . "' appeared in more than one A record!");
    }
  } else={
    $LogPrintExit2 debug $0 ("No address available... Ignoring.") false;
  }
}
