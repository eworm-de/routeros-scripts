#!rsc by RouterOS
# RouterOS script: dhcp-to-dns
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: lease-script, order=20
# requires RouterOS, version=7.16
#
# check DHCP leases and add/remove/update DNS entries
# https://rsc.eworm.de/doc/dhcp-to-dns.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global Domain;
  :global Identity;

  :global CleanName;
  :global EitherOr;
  :global IfThenElse;
  :global LogPrint;
  :global LogPrintOnce;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName 10 ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :local Ttl 5m;
  :local CommentPrefix ("managed by " . $ScriptName);
  :local CommentString ("--- " . $ScriptName . " above ---");

  :if ([ :len [ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ] ] = 0) do={
    /ip/dns/static/add name=$CommentString type=NXDOMAIN disabled=yes;
    $LogPrint warning $ScriptName ("Added disabled static dns record with name '" . $CommentString . "'.");
  }
  :local PlaceBefore ([ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ]->0);

  :foreach DnsRecord in=[ /ip/dns/static/find where comment~("^" . $CommentPrefix . "\\b") type=A ] do={
    :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
    :local DnsRecordInfo [ $ParseKeyValueStore ($DnsRecordVal->"comment") ];
    :local MacInServer ($DnsRecordInfo->"macaddress" . " in " . $DnsRecordInfo->"server");

    :if ([ :len [ /ip/dhcp-server/lease/find where active-mac-address=($DnsRecordInfo->"macaddress") \
         active-address=($DnsRecordVal->"address") server=($DnsRecordInfo->"server") status=bound ] ] > 0) do={
      $LogPrint debug $ScriptName ("Lease for " . $MacInServer . " (" . $DnsRecordVal->"name" . ") still exists. Not deleting record.");
    } else={
      :local Found false;
      $LogPrint info $ScriptName ("Lease expired for " . $MacInServer . ", deleting record (" . $DnsRecordVal->"name" . ").");
      /ip/dns/static/remove $DnsRecord;
      /ip/dns/static/remove [ find where type=CNAME comment=($DnsRecordVal->"comment") ];
    }
  }

  :foreach Lease in=[ /ip/dhcp-server/lease/find where status=bound ] do={
    :local LeaseVal;
    :do {
      :set LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
      :if ([ :len [ /ip/dhcp-server/lease/find where active-mac-address=($LeaseVal->"active-mac-address") status=bound ] ] > 1) do={
        $LogPrintOnce info $ScriptName ("Multiple bound leases found for mac-address " . ($LeaseVal->"active-mac-address") . "!");
      }
    } on-error={
      $LogPrint debug $ScriptName ("A lease just vanished, ignoring.");
    }

    :if ([ :len ($LeaseVal->"active-address") ] > 0) do={
      :local Comment ($CommentPrefix . ", macaddress=" . $LeaseVal->"active-mac-address" . ", server=" . $LeaseVal->"server");
      :local MacDash [ $CleanName ($LeaseVal->"active-mac-address") ];
      :local HostName [ $CleanName [ $EitherOr ([ $ParseKeyValueStore ($LeaseVal->"comment") ]->"hostname") ($LeaseVal->"host-name") ] ];
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
      :local MacInServer ($LeaseVal->"active-mac-address" . " in " . $LeaseVal->"server");

      :local DnsRecord [ /ip/dns/static/find where comment=$Comment type=A ];
      :if ([ :len $DnsRecord ] > 0) do={
        :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];

        :if ($DnsRecordVal->"address" = $LeaseVal->"active-address" && $DnsRecordVal->"name" = $FullA) do={
          $LogPrint debug $ScriptName ("The A record for " . $MacInServer . " (" . $FullA . ") does not need updating.");
        } else={
          $LogPrint info $ScriptName ("Updating A record for " . $MacInServer . " (" . $FullA . " -> " . $LeaseVal->"active-address" . ").");
          /ip/dns/static/set address=($LeaseVal->"active-address") name=$FullA $DnsRecord;
        }

        :local CName [ /ip/dns/static/find where comment=$Comment type=CNAME ];
        :if ([ :len $CName ] > 0) do={
          :local CNameVal [ /ip/dns/static/get $CName ];
          :if ($CNameVal->"name" != $FullCN || $CNameVal->"cname" != $FullA) do={
            $LogPrint info $ScriptName ("Deleting CNAME record with wrong data for " . $MacInServer . ".");
            /ip/dns/static/remove $CName;
          }
        }
        :if ([ :len $HostName ] > 0 && [ :len [ /ip/dns/static/find where name=$FullCN type=CNAME ] ] = 0) do={
          $LogPrint info $ScriptName ("Adding CNAME record for " . $MacInServer . " (" . $FullCN . " -> " . $FullA . ").");
          /ip/dns/static/add name=$FullCN type=CNAME cname=$FullA ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
        }

      } else={
        $LogPrint info $ScriptName ("Adding A record for " . $MacInServer . " (" . $FullA . " -> " . $LeaseVal->"active-address" . ").");
        /ip/dns/static/add name=$FullA type=A address=($LeaseVal->"active-address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
        :if ([ :len $HostName ] > 0 && [ :len [ /ip/dns/static/find where name=$FullCN type=CNAME ] ] = 0) do={
          $LogPrint info $ScriptName ("Adding CNAME record for " . $MacInServer . " (" . $FullCN . " -> " . $FullA . ").");
          /ip/dns/static/add name=$FullCN type=CNAME cname=$FullA ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
        }
      }

      :if ([ :len [ /ip/dns/static/find where name=$FullA type=A ] ] > 1) do={
        $LogPrintOnce warning $ScriptName ("The name '" . $FullA . "' appeared in more than one A record!");
      }
    } else={
      $LogPrint debug $ScriptName ("No address available... Ignoring.");
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
