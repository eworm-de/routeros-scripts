#!rsc by RouterOS
# RouterOS script: netwatch-dns
# Copyright (c) 2022-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# monitor and manage dns/doh with netwatch
# https://git.eworm.de/cgit/routeros-scripts/about/doc/netwatch-dns.md

:local 0 "netwatch-dns";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global CertificateAvailable;
:global EitherOr;
:global IsDNSResolving;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;

$ScriptLock $0;

:if ([ /system/resource/get uptime ] < 5m30s) do={
  $LogPrintExit2 info $0 ("System just booted, giving netwatch some time to settle.") true;
}

:local DnsServers ({});
:local DnsFallback ({});
:local DnsCurrent [ /ip/dns/get servers ];

:foreach Host in=[ /tool/netwatch/find where comment~"\\bdns\\b" status="up" ] do={
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

:local DohCertVerify [ /ip/dns/get verify-doh-cert ];
:local DohCurrent [ /ip/dns/get use-doh-server ];
:local DohServers ({});

:foreach Host in=[ /tool/netwatch/find where comment~"\\bdoh\\b" status="up" ] do={
  :local HostVal [ /tool/netwatch/get $Host ];
  :local HostInfo [ $ParseKeyValueStore ($HostVal->"comment") ];
  :local HostName [ /ip/dns/static/find where name address=($HostVal->"host") \
      (!type or type="A" or type="AAAA") !disabled !dynamic ];
  :if ([ :len $HostName ] > 0) do={
    :set HostName [ /ip/dns/static/get ($HostName->0) name ];
  }

  :if ($HostInfo->"doh" = true && $HostInfo->"disabled" != true) do={
    :if ([ :len ($HostInfo->"doh-url") ] = 0) do={
      :set ($HostInfo->"doh-url") ("https://" . [ $EitherOr $HostName ($HostVal->"host") ] . "/dns-query");
    }

    :if ($DohCurrent = $HostInfo->"doh-url") do={
      $LogPrintExit2 debug $0 ("Current DoH server is still up.") true;
    }

    :set ($DohServers->[ :len $DohServers ]) $HostInfo;
  }
}

:if ([ :len $DohCurrent ] > 0 && [ :len $DohServers ] = 0) do={
  $LogPrintExit2 info $0 ("DoH server (" . $DohCurrent . ") is down, disabling.") false;
  /ip/dns/set use-doh-server="";
  /ip/dns/cache/flush;
}

:foreach DohServer in=$DohServers do={
  $LogPrintExit2 info $0 ("Updating DoH server: " . ($DohServer->"doh-url")) false;
  :if ([ :len ($DohServer->"doh-cert") ] > 0) do={
    :set DohCertVerify true;
    /ip/dns/set use-doh-server="";
    :if ([ $CertificateAvailable ($DohServer->"doh-cert") ] = false) do={
      $LogPrintExit2 warning $0 ("Downloading certificate failed, trying without.") false;
    }
  }
  /ip/dns/set use-doh-server=($DohServer->"doh-url") verify-doh-cert=$DohCertVerify;
  /ip/dns/cache/flush;
  :if ([ $IsDNSResolving ] = true) do={
    $LogPrintExit2 debug $0 ("DoH server is functional.") true;
  } else={
    /ip/dns/set use-doh-server="";
    $LogPrintExit2 warning $0 ("DoH server not functional, trying next.") false;
  }
}
