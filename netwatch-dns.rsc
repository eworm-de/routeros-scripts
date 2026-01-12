#!rsc by RouterOS
# RouterOS script: netwatch-dns
# Copyright (c) 2022-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.17
# requires device-mode, fetch
#
# monitor and manage dns/doh with netwatch
# https://rsc.eworm.de/doc/netwatch-dns.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global CertificateAvailable;
  :global EitherOr;
  :global IsDNSResolving;
  :global LogPrint;
  :global LogPrintOnce;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :local SettleTime (5m30s - [ /system/resource/get uptime ]);
  :if ($SettleTime > 0s) do={
    $LogPrint info $ScriptName ("System just booted, giving netwatch " . $SettleTime . " to settle.");
    :set ExitOK true;
    :error true;
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
      $LogPrint info $ScriptName ("Updating DNS servers: " . [ :tostr $DnsServers ]);
      /ip/dns/set servers=$DnsServers;
      /ip/dns/cache/flush;
    }
  } else={
    :if ([ :len $DnsFallback ] > 0) do={
      :if ($DnsFallback != $DnsCurrent) do={
        $LogPrint info $ScriptName ("Updating DNS servers to fallback: " . [ :tostr $DnsFallback ]);
        /ip/dns/set servers=$DnsFallback;
        /ip/dns/cache/flush;
      }
    }
  }

  :local DohCurrent [ /ip/dns/get use-doh-server ];
  :local DohServers ({});
  :foreach Host in=[ /tool/netwatch/find where comment~"\\bdoh\\b" status="up" ] do={
    :local HostVal [ /tool/netwatch/get $Host ];
    :local HostInfo [ $ParseKeyValueStore ($HostVal->"comment") ];
    :local HostName [ /ip/dns/static/find where name address=($HostVal->"host") \
        (type="A" or type="AAAA") !disabled !dynamic ];
    :if ([ :len $HostName ] > 0) do={
      :set HostName [ /ip/dns/static/get ($HostName->0) name ];
    }

    :if ($HostInfo->"doh" = true && $HostInfo->"disabled" != true) do={
      :if ([ :len ($HostInfo->"doh-url") ] = 0) do={
        :set ($HostInfo->"doh-url") ("https://" . [ $EitherOr $HostName ($HostVal->"host") ] . "/dns-query");
      }

      :if ($DohCurrent = $HostInfo->"doh-url" && [ $IsDNSResolving ] = true) do={
        $LogPrint debug $ScriptName ("Current DoH server is still up and resolving: " . $DohCurrent);
        :set ExitOK true;
        :error true;
      }

      :set ($DohServers->[ :len $DohServers ]) $HostInfo;
    }
  }

  :if ([ :len $DohCurrent ] > 0) do={
    $LogPrint info $ScriptName ("Current DoH server is down or not resolving, disabling: " . $DohCurrent);
    /ip/dns/set use-doh-server="";
    /ip/dns/cache/flush;
  }

  :foreach DohServer in=$DohServers do={
    :if ([ :len ($DohServer->"doh-cert") ] > 0) do={
      :if ([ $CertificateAvailable ($DohServer->"doh-cert") "dns" ] = false) do={
        $LogPrint warning $ScriptName ("Downloading certificate failed, trying without.");
      }
    }

    :local Data false;
    :onerror Err {
      :retry {
        :set Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
          http-header-field=({ "accept: application/dns-message" }) \
          url=(($DohServer->"doh-url") . "?dns=" . [ :convert to=base64 ([ :rndstr length=2 ] . \
          "\01\00" . "\00\01" . "\00\00" . "\00\00" . "\00\00" . "\09doh-check\05eworm\02de\00" . \
          "\00\10" . "\00\01") ]) as-value ]->"data");
      } delay=1s max=3;
    } do={
      $LogPrint warning $ScriptName ("Request to DoH server " . ($DohServer->"doh-url") . \
          " failed: " . $Err);
    }

    :if ($Data != false) do={
      :if ([ :typeof [ :find $Data "doh-check-OK" ] ] = "num") do={
        /ip/dns/set use-doh-server=($DohServer->"doh-url") verify-doh-cert=yes;
        :if ([ /certificate/settings/get crl-use ] = true) do={
          $LogPrintOnce warning $ScriptName ("Configured to use CRL, that can cause severe issue!");
        }
        /ip/dns/cache/flush;
        $LogPrint info $ScriptName ("Setting DoH server: " . ($DohServer->"doh-url"));
        :set ExitOK true;
        :error true;
      } else={
        $LogPrint warning $ScriptName ("Received unexpected response from DoH server: " . \
          ($DohServer->"doh-url"));
      }
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
