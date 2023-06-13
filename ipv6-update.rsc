#!rsc by RouterOS
# RouterOS script: ipv6-update
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# update firewall and dns settings on IPv6 prefix change
# https://git.eworm.de/cgit/routeros-scripts/about/doc/ipv6-update.md

:local 0 "ipv6-update";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local PdPrefix $"pd-prefix";

:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0;

:if ([ :typeof $PdPrefix ] = "nothing") do={
  $LogPrintExit2 error $0 ("This script is supposed to run from ipv6 dhcp-client.") true;
}

:local Pool [ /ipv6/pool/get [ find where prefix=$PdPrefix ] name ];
:if ([ :len [ /ipv6/firewall/address-list/find where comment=("ipv6-pool-" . $Pool) ] ] = 0) do={
  /ipv6/firewall/address-list/add list=("ipv6-pool-" . $Pool) address=:: comment=("ipv6-pool-" . $Pool);
  $LogPrintExit2 warning $0 ("Added ipv6 address list entry for ipv6-pool-" . $Pool) false;
}
:local AddrList [ /ipv6/firewall/address-list/find where comment=("ipv6-pool-" . $Pool) ];
:local OldPrefix [ /ipv6/firewall/address-list/get ($AddrList->0) address ];

:if ($OldPrefix != $PdPrefix) do={
  $LogPrintExit2 info $0 ("Updating IPv6 address list with new IPv6 prefix " . $PdPrefix) false;
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

        $LogPrintExit2 info $0 ("Updating IPv6 address list with new IPv6 host address " . $Address . \
          " from interface " . ($Comment->"interface")) false;
        /ipv6/firewall/address-list/set address=$Address $ListEntry;
      } else={
        $LogPrintExit2 info $0 ("Updating IPv6 address list with new IPv6 prefix " . $Prefix . \
          " from interface " . ($Comment->"interface")) false;
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

      $LogPrintExit2 info $0 ("Updating DNS record for " . ($RecordVal->"name") . \
        ($RecordVal->"regexp") . " to " . $Address) false;
      /ip/dns/static/set address=$Address $Record;
    }
  }
}
