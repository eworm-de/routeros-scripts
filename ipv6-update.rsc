#!rsc by RouterOS
# RouterOS script: ipv6-update
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# update firewall and dns settings on IPv6 prefix change
# https://rsc.eworm.de/doc/ipv6-update.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :local NaAddress $"na-address";
  :local NaValid $"na-valid";
  :local PdPrefix $"pd-prefix";
  :local PdValid $"pd-valid";

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :if ([ :typeof $NaAddress ] = "str") do={
    $LogPrint info $ScriptName ("An address (" . $NaAddress . ") was acquired, not a prefix. Ignoring.");
    :set ExitOK true;
    :error false;
  }

  :if ([ :typeof $PdPrefix ] = "nothing" || [ :typeof $PdValid ] = "nothing") do={
    $LogPrint error $ScriptName ("This script is supposed to run from ipv6 dhcp-client.");
    :set ExitOK true;
    :error false;
  }

  :if ($PdValid != 1) do={
    $LogPrint info $ScriptName ("The prefix " . $PdPrefix . " is no longer valid. Ignoring.");
    :set ExitOK true;
    :error false;
  }

  :local Pool [ /ipv6/pool/get [ find where prefix=$PdPrefix ] name ];
  :if ([ :len [ /ipv6/firewall/address-list/find where comment=("ipv6-pool-" . $Pool) ] ] = 0) do={
    /ipv6/firewall/address-list/add list=("ipv6-pool-" . $Pool) address=:: comment=("ipv6-pool-" . $Pool) dynamic=yes;
    $LogPrint warning $ScriptName ("Added dynamic ipv6 address list entry for ipv6-pool-" . $Pool);
  }
  :local AddrList [ /ipv6/firewall/address-list/find where comment=("ipv6-pool-" . $Pool) ];
  :local OldPrefix [ /ipv6/firewall/address-list/get ($AddrList->0) address ];

  :if ($OldPrefix != $PdPrefix) do={
    $LogPrint info $ScriptName ("Updating IPv6 address list with new IPv6 prefix " . $PdPrefix);
    /ipv6/firewall/address-list/set address=$PdPrefix $AddrList;

    # give the interfaces a moment to receive their addresses
    :delay 2s;

    :foreach ListEntry in=[ /ipv6/firewall/address-list/find where comment~("^ipv6-pool-" . $Pool . ",") ] do={
      :local ListEntryVal [ /ipv6/firewall/address-list/get $ListEntry ];
      :local Comment [ $ParseKeyValueStore ($ListEntryVal->"comment") ];

      :local Prefix [ /ipv6/address/find where from-pool=$Pool interface=($Comment->"interface") global ];
      :if ([ :len $Prefix ] = 1) do={
        :set Prefix [ /ipv6/address/get $Prefix address ];

        :if ([ :typeof [ :find ($ListEntryVal->"address") "/128" ] ] = "num" ) do={
          :set Prefix ([ :toip6 [ :pick $Prefix 0 [ :find $Prefix "/64" ] ] ] & ffff:ffff:ffff:ffff::);
          :local Address ($ListEntryVal->"address");
          :local Address ($Prefix | ([ :toip6 [ :pick $Address 0 [ :find $Address "/128" ] ] ] & ::ffff:ffff:ffff:ffff));

          $LogPrint info $ScriptName ("Updating IPv6 address list with new IPv6 host address " . $Address . \
            " from interface " . ($Comment->"interface"));
          /ipv6/firewall/address-list/set address=$Address $ListEntry;
        } else={
          $LogPrint info $ScriptName ("Updating IPv6 address list with new IPv6 prefix " . $Prefix . \
            " from interface " . ($Comment->"interface"));
          /ipv6/firewall/address-list/set address=$Prefix $ListEntry;
        }
      }
    }

    :foreach Record in=[ /ip/dns/static/find where comment~("^ipv6-pool-" . $Pool . ",") ] do={
      :local RecordVal [ /ip/dns/static/get $Record ];
      :local Comment [ $ParseKeyValueStore ($RecordVal->"comment") ];

      :local Prefix [ /ipv6/address/find where from-pool=$Pool interface=($Comment->"interface") global ];
      :if ([ :len $Prefix ] = 1) do={
        :set Prefix [ /ipv6/address/get $Prefix address ];
        :set Prefix ([ :toip6 [ :pick $Prefix 0 [ :find $Prefix "/64" ] ] ] & ffff:ffff:ffff:ffff::);
        :local Address ($Prefix | ([ :toip6 ($RecordVal->"address") ] & ::ffff:ffff:ffff:ffff));

        $LogPrint info $ScriptName ("Updating DNS record for " . ($RecordVal->"name") . \
          ($RecordVal->"regexp") . " to " . $Address);
        /ip/dns/static/set address=$Address $Record;
      }
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
