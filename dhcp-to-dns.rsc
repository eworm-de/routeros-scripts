#!rsc by RouterOS
# RouterOS script: dhcp-to-dns
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: dhcpv4-server-lease, order=20
# requires RouterOS, version=7.22
#
# check DHCP leases and add/remove/update DNS entries
# https://rsc.eworm.de/doc/dhcp-to-dns.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=dhcp-to-dns, schema=96d193afd6225330e8e948bff1c489f075720758d514a6288540b978f27c8e6d
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"dhcp-to-dns.address.missing") "No address available... Ignoring.";
:set ($LanguageEnglish->"dhcp-to-dns.cname.adding") "Adding CNAME record for {lease} ({name} -> {target}).";
:set ($LanguageEnglish->"dhcp-to-dns.cname.deleting") "Deleting CNAME record with wrong data for {lease}.";
:set ($LanguageEnglish->"dhcp-to-dns.lease.exists") "Lease for {lease} ({name}) still exists. Not deleting record.";
:set ($LanguageEnglish->"dhcp-to-dns.lease.expired") "Lease expired for {lease}, deleting record ({name}).";
:set ($LanguageEnglish->"dhcp-to-dns.lease.ignored") "Lease for {mac} is ignored... Skipping.";
:set ($LanguageEnglish->"dhcp-to-dns.lease.label") "{mac} in {server}";
:set ($LanguageEnglish->"dhcp-to-dns.lease.label.current") "{mac} in {server}";
:set ($LanguageEnglish->"dhcp-to-dns.lease.vanished") "A lease just vanished, ignoring.";
:set ($LanguageEnglish->"dhcp-to-dns.leases.multiple") "Multiple bound leases found for mac-address {mac}!";
:set ($LanguageEnglish->"dhcp-to-dns.marker.added") "Added disabled static dns record with name '{name}'.";
:set ($LanguageEnglish->"dhcp-to-dns.record.adding") "Adding A record for {lease} ({name} -> {address}).";
:set ($LanguageEnglish->"dhcp-to-dns.record.current") "The A record for {lease} ({name}) does not need updating.";
:set ($LanguageEnglish->"dhcp-to-dns.record.updating") "Updating A record for {lease} ({name} -> {address}).";
:set ($LanguageEnglish->"dhcp-to-dns.records.multiple") "The name '{name}' appeared in more than one A record!";
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
  :global Identity;

  :global CleanName;
  :global EitherOr;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global LogPrintOnce;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName 10 ] = false) do={
    :exit;
  }

  :local Ttl 5m;
  :local CommentPrefix ("managed by " . $ScriptName);
  :local CommentString ("--- " . $ScriptName . " above ---");

  :if ([ :len [ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ] ] = 0) do={
    /ip/dns/static/add name=$CommentString type=NXDOMAIN disabled=yes;
    $LogPrint warning $ScriptName [ $Translate "dhcp-to-dns.marker.added" \
        ({ name=$CommentString }) ];
  }
  :local PlaceBefore ([ /ip/dns/static/find where (name=$CommentString or (comment=$CommentString and name=-)) type=NXDOMAIN disabled ]->0);

  :foreach DnsRecord in=[ /ip/dns/static/find where comment~("^" . $CommentPrefix . "\\b") type=A ] do={
    :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];
    :local DnsRecordInfo [ $ParseKeyValueStore ($DnsRecordVal->"comment") ];
    :local MacInServer [ $Translate "dhcp-to-dns.lease.label" \
        ({ mac=($DnsRecordInfo->"macaddress"); server=($DnsRecordInfo->"server") }) ];

    :if ([ :len [ /ip/dhcp-server/lease/find where active-mac-address=($DnsRecordInfo->"macaddress") \
         active-address=($DnsRecordVal->"address") server=($DnsRecordInfo->"server") status=bound ] ] > 0) do={
      $LogPrint debug $ScriptName [ $Translate "dhcp-to-dns.lease.exists" \
          ({ lease=$MacInServer; name=($DnsRecordVal->"name") }) ];
    } else={
      $LogPrint info $ScriptName [ $Translate "dhcp-to-dns.lease.expired" \
          ({ lease=$MacInServer; name=($DnsRecordVal->"name") }) ];
      /ip/dns/static/remove $DnsRecord;
      /ip/dns/static/remove [ find where type=CNAME comment=($DnsRecordVal->"comment") ];
    }
  }

  :foreach Lease in=[ /ip/dhcp-server/lease/find where status=bound ] do={
    :local LeaseVal;
    :do {
      :set LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
      :if ([ :len [ /ip/dhcp-server/lease/find where active-mac-address=($LeaseVal->"active-mac-address") status=bound ] ] > 1) do={
        $LogPrintOnce info $ScriptName [ $Translate "dhcp-to-dns.leases.multiple" \
            ({ mac=($LeaseVal->"active-mac-address") }) ];
      }
    } on-error={
      $LogPrint debug $ScriptName [ $Translate "dhcp-to-dns.lease.vanished" ];
      :continue;
    }
    :local LeaseInfo [ $ParseKeyValueStore ($LeaseVal->"comment") ];

    :if ([ :len ($LeaseVal->"active-address") ] = 0) do={
      $LogPrint debug $ScriptName [ $Translate "dhcp-to-dns.address.missing" ];
      :continue;
    }

    :local Network [ /ip/dhcp-server/network/find where ($LeaseVal->"active-address") in address ];
    :local NetworkVal;
    :if ([ :len $Network ] > 0) do={
      :set NetworkVal [ /ip/dhcp-server/network/get ($Network->0) ];
    }
    :local NetworkInfo [ $ParseKeyValueStore ($NetworkVal->"comment") ];

    :if ($LeaseInfo->"dns-ignore" = true || $NetworkInfo->"dns-ignore" = true) do={
      $LogPrint debug $ScriptName [ $Translate "dhcp-to-dns.lease.ignored" \
          ({ mac=($LeaseVal->"active-mac-address") }) ];
      :continue;
    }

    :local Comment ($CommentPrefix . ", macaddress=" . $LeaseVal->"active-mac-address" . ", server=" . $LeaseVal->"server");
    :local MacDash [ $CleanName ($LeaseVal->"active-mac-address") ];
    :local HostName [ $CleanName [ $EitherOr ($LeaseInfo->"hostname") ($LeaseVal->"host-name") ] ];
    :local NetDomain ([ $IfThenElse ([ :len ($NetworkInfo->"name-extra") ] > 0) ($NetworkInfo->"name-extra" . ".") ] . \
      [ $EitherOr [ $EitherOr ($NetworkInfo->"domain") ($NetworkVal->"domain") ] $Domain ]);
    :local FullA [ :convert transform=lc ($MacDash . "." . $NetDomain) ];
    :local CNameDomain [ $EitherOr ($LeaseInfo->"cname-domain") ($NetworkInfo->"cname-domain") ];
    :local FullCN [ :convert transform=lc ($HostName . "." . [ $EitherOr $CNameDomain $NetDomain ]) ];
    :local MacInServer [ $Translate "dhcp-to-dns.lease.label.current" \
        ({ mac=($LeaseVal->"active-mac-address"); server=($LeaseVal->"server") }) ];

    :local DnsRecord [ /ip/dns/static/find where comment=$Comment type=A ];
    :if ([ :len $DnsRecord ] > 0) do={
      :local DnsRecordVal [ /ip/dns/static/get $DnsRecord ];

      :if ($DnsRecordVal->"address" = $LeaseVal->"active-address" && $DnsRecordVal->"name" = $FullA) do={
        $LogPrint debug $ScriptName [ $Translate "dhcp-to-dns.record.current" \
            ({ lease=$MacInServer; name=$FullA }) ];
      } else={
        $LogPrint info $ScriptName [ $Translate "dhcp-to-dns.record.updating" \
            ({ lease=$MacInServer; name=$FullA; address=($LeaseVal->"active-address") }) ];
        /ip/dns/static/set address=($LeaseVal->"active-address") name=$FullA $DnsRecord;
      }

      :local CName [ /ip/dns/static/find where comment=$Comment type=CNAME ];
      :if ([ :len $CName ] > 0) do={
        :local CNameVal [ /ip/dns/static/get $CName ];
        :if ($CNameVal->"name" != $FullCN || $CNameVal->"cname" != $FullA) do={
          $LogPrint info $ScriptName [ $Translate "dhcp-to-dns.cname.deleting" \
              ({ lease=$MacInServer }) ];
          /ip/dns/static/remove $CName;
        }
      }
      :if ([ :len $HostName ] > 0 && [ :len [ /ip/dns/static/find where name=$FullCN type=CNAME ] ] = 0) do={
        $LogPrint info $ScriptName [ $Translate "dhcp-to-dns.cname.adding" \
            ({ lease=$MacInServer; name=$FullCN; target=$FullA }) ];
        /ip/dns/static/add name=$FullCN type=CNAME cname=$FullA ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }

    } else={
      $LogPrint info $ScriptName [ $Translate "dhcp-to-dns.record.adding" \
          ({ lease=$MacInServer; name=$FullA; address=($LeaseVal->"active-address") }) ];
      /ip/dns/static/add name=$FullA type=A address=($LeaseVal->"active-address") ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      :if ([ :len $HostName ] > 0 && [ :len [ /ip/dns/static/find where name=$FullCN type=CNAME ] ] = 0) do={
        $LogPrint info $ScriptName [ $Translate "dhcp-to-dns.cname.adding" \
            ({ lease=$MacInServer; name=$FullCN; target=$FullA }) ];
        /ip/dns/static/add name=$FullCN type=CNAME cname=$FullA ttl=$Ttl comment=$Comment place-before=$PlaceBefore;
      }
    }

    :if ([ :len [ /ip/dns/static/find where name=$FullA type=A ] ] > 1) do={
      $LogPrintOnce warning $ScriptName [ $Translate "dhcp-to-dns.records.multiple" \
          ({ name=$FullA }) ];
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
