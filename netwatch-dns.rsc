#!rsc by RouterOS
# RouterOS script: netwatch-dns
# Copyright (c) 2022-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# monitor and manage dns/doh with netwatch
# https://git.eworm.de/cgit/routeros-scripts/about/doc/netwatch-dns.md

:local 0 "netwatch-dns";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global CertificateAvailable;
:global EitherOr;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0;

:if ([ /system/resource/get uptime ] < 5m) do={
  $LogPrintExit2 info $0 ("System just booted, giving netwatch some time to settle.") true;
}

:local DnsServers ({});
:local DnsFallback ({});
:local DnsCurrent [ /ip/dns/get servers ];

:foreach Host in=[ /tool/netwatch/find where comment~"dns" status="up" ] do={
  :local HostVal [ /tool/netwatch/get $Host ];
  :local HostInfo [ $ParseKeyValueStore ($HostVal->"comment") ];

  :if ($HostInfo->"disabled" != true) do={
    :if ($HostInfo->"dns" = true) do={
      :set DnsServers ($DnsServers, $HostVal->"host");
    }
    :if ($HostInfo->"dns-fallback" = true) do={
      :set DnsFallback ($DnsFallback, $HostVal->"host");
    }
  }
}

:if ([ :len $DnsServers ] > 0) do={
  :if ($DnsServers != $DnsCurrent) do={
    $LogPrintExit2 info $0 ("Updating DNS servers: " . [ :tostr $DnsServers ]) false;
    /ip/dns/set servers=$DnsServers;
    /ip/dns/cache/flush;
  }
} else={
  :if ([ :len $DnsFallback ] > 0) do={
    :if ($DnsFallback != $DnsCurrent) do={
      $LogPrintExit2 info $0 ("Updating DNS servers to fallback: " . \
          [ :tostr $DnsFallback ]) false;
      /ip/dns/set servers=$DnsFallback;
      /ip/dns/cache/flush;
    }
  }
}

:local DohServer "";
:local DohCurrent [ /ip/dns/get use-doh-server ];
:local DohCert "";

:foreach Host in=[ /tool/netwatch/find where comment~"doh" status="up" ] do={
  :local HostVal [ /tool/netwatch/get $Host ];
  :local HostInfo [ $ParseKeyValueStore ($HostVal->"comment") ];

  :if ($HostInfo->"doh" = true && $HostInfo->"disabled" != true && $DohServer = "") do={
    :set DohServer [ $EitherOr ($HostInfo->"doh-url") \
        ("https://" . $HostVal->"host" . "/dns-query") ];
    :set DohCert ($HostInfo->"doh-cert");
  }
}

:if ($DohServer != "") do={
  :if ($DohServer != $DohCurrent) do={
    $LogPrintExit2 info $0 ("Updating DoH server: " . $DohServer) false;
    :if ([ :len $DohCert ] > 0) do={
      /ip/dns/set use-doh-server="";
      :if ([ $CertificateAvailable $DohCert ] = false) do={
        $LogPrintExit2 warning $0 ("Downloading certificate failed, trying without.") false;
      }
    }
    /ip/dns/set use-doh-server=$DohServer;
    /ip/dns/cache/flush;
  }
} else={
  :if ($DohCurrent != "") do={
    $LogPrintExit2 info $0 ("DoH server (" . $DohCurrent . ") is down, disabling.") false;
    /ip/dns/set use-doh-server="";
    /ip/dns/cache/flush;
  }
}
