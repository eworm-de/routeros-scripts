#!rsc by RouterOS
# RouterOS script: ipv6-update
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# provides: dhcpv6-client-lease, order=40
#
# update firewall and dns settings on IPv6 prefix change
# https://rsc.eworm.de/doc/ipv6-update.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=ipv6-update, schema=d502241c31fb73e9c3245e499a026333b5c7b5265d927b18a2a24bf7948fb823
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"ipv6-update.address.ignored") "An address ({address}) was acquired, not a prefix. Ignoring.";
:set ($LanguageEnglish->"ipv6-update.context.invalid") "This script is supposed to run from ipv6 dhcp-client.";
:set ($LanguageEnglish->"ipv6-update.dns.updating") "Updating DNS record for {name}{regexp} to {address}";
:set ($LanguageEnglish->"ipv6-update.host.updating") "Updating IPv6 address list with new IPv6 host address {address} from interface {interface}";
:set ($LanguageEnglish->"ipv6-update.interface.prefix.updating") "Updating IPv6 address list with new IPv6 prefix {prefix} from interface {interface}";
:set ($LanguageEnglish->"ipv6-update.list.added") "Added dynamic ipv6 address list entry for ipv6-pool-{pool}";
:set ($LanguageEnglish->"ipv6-update.prefix.invalid") "The prefix {prefix} is no longer valid. Ignoring.";
:set ($LanguageEnglish->"ipv6-update.prefix.updating") "Updating IPv6 address list with new IPv6 prefix {prefix}";
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

  :global EitherOr;
  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :global DHCPv6ClientLeaseVars;

  :local NaAddress [ $EitherOr $"na-address" ($DHCPv6ClientLeaseVars->"na-address") ];
  :local NaValid [ $EitherOr $"na-valid" ($DHCPv6ClientLeaseVars->"na-valid") ];
  :local PdPrefix [ $EitherOr $"pd-prefix" ($DHCPv6ClientLeaseVars->"pd-prefix") ];
  :local PdValid [ $EitherOr $"pd-valid" ($DHCPv6ClientLeaseVars->"pd-valid") ];

  :if ([ $ScriptLock $ScriptName 10 ] = false) do={
    :exit;
  }

  :if ([ :typeof $NaAddress ] = "str") do={
    $LogPrint info $ScriptName [ $Translate "ipv6-update.address.ignored" \
        ({ "address"=$NaAddress }) ];
    :exit;
  }

  :if ([ :typeof $PdPrefix ] = "nothing" || [ :typeof $PdValid ] = "nothing") do={
    $LogPrint error $ScriptName [ $Translate "ipv6-update.context.invalid" ];
    :exit;
  }

  :if ($PdValid != 1) do={
    $LogPrint info $ScriptName [ $Translate "ipv6-update.prefix.invalid" \
        ({ prefix=[ :tostr $PdPrefix ] }) ];
    :exit;
  }

  :local Pool [ /ipv6/pool/get [ find where prefix=$PdPrefix ] name ];
  :if ([ :len [ /ipv6/firewall/address-list/find where comment=("ipv6-pool-" . $Pool) ] ] = 0) do={
    /ipv6/firewall/address-list/add list=("ipv6-pool-" . $Pool) address=:: comment=("ipv6-pool-" . $Pool) dynamic=yes;
    $LogPrint info $ScriptName [ $Translate "ipv6-update.list.added" \
        ({ pool=$Pool }) ];
  }
  :local AddrList [ /ipv6/firewall/address-list/find where comment=("ipv6-pool-" . $Pool) ];
  :local OldPrefix [ /ipv6/firewall/address-list/get ($AddrList->0) address ];

  :local SubPool ({});
  :foreach Sub in=[ /ipv6/pool/find where from-pool=$Pool ] do={
    :set SubPool ($SubPool, [ /ipv6/pool/get $Sub name ]);
  }

  :if ($OldPrefix != $PdPrefix) do={
    $LogPrint info $ScriptName [ $Translate "ipv6-update.prefix.updating" \
        ({ prefix=$PdPrefix }) ];
    /ipv6/firewall/address-list/set address=$PdPrefix $AddrList;

    # give the interfaces a moment to receive their addresses
    :delay 2s;

    :foreach ListEntry in=[ /ipv6/firewall/address-list/find where comment~("^ipv6-pool-" . $Pool . ",") ] do={
      :local ListEntryVal [ /ipv6/firewall/address-list/get $ListEntry ];
      :local Comment [ $ParseKeyValueStore ($ListEntryVal->"comment") ];

      :local Prefix [ /ipv6/address/find where (from-pool=$Pool or from-pool in $SubPool) \
          interface=($Comment->"interface") global ];
      :if ([ :len $Prefix ] = 1) do={
        :set Prefix [ /ipv6/address/get $Prefix address ];

        :if ([ :typeof [ :find ($ListEntryVal->"address") "/128" ] ] = "num" ) do={
          :set Prefix ([ :toip6 [ :pick $Prefix 0 [ :find $Prefix "/64" ] ] ] & ffff:ffff:ffff:ffff::);
          :local Address ($ListEntryVal->"address");
          :local Address ($Prefix | ([ :toip6 [ :pick $Address 0 [ :find $Address "/128" ] ] ] & ::ffff:ffff:ffff:ffff));

          $LogPrint info $ScriptName [ $Translate "ipv6-update.host.updating" \
              ({ address=$Address; interface=($Comment->"interface") }) ];
          /ipv6/firewall/address-list/set address=$Address $ListEntry;
        } else={
          $LogPrint info $ScriptName [ $Translate "ipv6-update.interface.prefix.updating" \
              ({ prefix=$Prefix; interface=($Comment->"interface") }) ];
          /ipv6/firewall/address-list/set address=$Prefix $ListEntry;
        }
      }
    }

    :foreach Record in=[ /ip/dns/static/find where comment~("^ipv6-pool-" . $Pool . ",") ] do={
      :local RecordVal [ /ip/dns/static/get $Record ];
      :local Comment [ $ParseKeyValueStore ($RecordVal->"comment") ];

      :local Prefix [ /ipv6/address/find where (from-pool=$Pool or from-pool in $SubPool) \
          interface=($Comment->"interface") global ];
      :if ([ :len $Prefix ] = 1) do={
        :set Prefix [ /ipv6/address/get $Prefix address ];
        :set Prefix ([ :toip6 [ :pick $Prefix 0 [ :find $Prefix "/64" ] ] ] & ffff:ffff:ffff:ffff::);
        :local Address ($Prefix | ([ :toip6 ($RecordVal->"address") ] & ::ffff:ffff:ffff:ffff));

        $LogPrint info $ScriptName [ $Translate "ipv6-update.dns.updating" \
            ({ name=($RecordVal->"name"); regexp=[ :tostr ($RecordVal->"regexp") ]; address=$Address }) ];
        /ip/dns/static/set address=$Address $Record;
      }
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
