#!rsc by RouterOS
# RouterOS script: netwatch-dns
# Copyright (c) 2022-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch
#
# monitor and manage dns/doh with netwatch
# https://rsc.eworm.de/doc/netwatch-dns.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=netwatch-dns, schema=a990191facc83c19ae4d95e097a5f7ec17573be4bce019c61e2ca3dcdffebf43
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"netwatch-dns.certificate.failed") "Downloading certificate '{name}' failed, trying without.";
:set ($LanguageEnglish->"netwatch-dns.crl.warning") "Configured to use CRL, that can cause severe issue!";
:set ($LanguageEnglish->"netwatch-dns.dns.fallback") "Updating DNS servers to fallback: {servers}";
:set ($LanguageEnglish->"netwatch-dns.dns.updating") "Updating DNS servers: {servers}";
:set ($LanguageEnglish->"netwatch-dns.doh.current") "Current DoH server is still up and resolving: {server}";
:set ($LanguageEnglish->"netwatch-dns.doh.disabling") "Current DoH server is down or not resolving, disabling: {server}";
:set ($LanguageEnglish->"netwatch-dns.doh.setting") "Setting DoH server: {server}";
:set ($LanguageEnglish->"netwatch-dns.request.failed") "Request to DoH server {server} failed: {error}";
:set ($LanguageEnglish->"netwatch-dns.response.invalid") "Received unexpected response from DoH server: {server}";
:set ($LanguageEnglish->"netwatch-dns.settling") "System just booted, giving netwatch {duration} to settle.";
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

  :global CertificateAvailable;
  :global EitherOr;
  :global IsDNSResolving;
  :global LogPrint;
  :global Translate;
  :global LogPrintOnce;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :local SettleTime (5m30s - [ /system/resource/get uptime ]);
  :if ($SettleTime > 0s) do={
    $LogPrint info $ScriptName [ $Translate "netwatch-dns.settling" \
        ({ duration=$SettleTime }) ];
    :exit;
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
      $LogPrint info $ScriptName [ $Translate "netwatch-dns.dns.updating" \
          ({ servers=[ :tostr $DnsServers ] }) ];
      /ip/dns/set servers=$DnsServers;
      /ip/dns/cache/flush;
    }
  } else={
    :if ([ :len $DnsFallback ] > 0) do={
      :if ($DnsFallback != $DnsCurrent) do={
        $LogPrint info $ScriptName [ $Translate "netwatch-dns.dns.fallback" \
            ({ servers=[ :tostr $DnsFallback ] }) ];
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
        $LogPrint debug $ScriptName [ $Translate "netwatch-dns.doh.current" \
            ({ server=$DohCurrent }) ];
        :exit;
      }

      :set ($DohServers->[ :len $DohServers ]) $HostInfo;
    }
  }

  :if ([ :len $DohCurrent ] > 0) do={
    $LogPrint info $ScriptName [ $Translate "netwatch-dns.doh.disabling" \
        ({ server=$DohCurrent }) ];
    /ip/dns/set use-doh-server="";
    /ip/dns/cache/flush;
  }

  :foreach DohServer in=$DohServers do={
    :foreach DohCert in=[ :toarray delimiter=":" [ :tostr ($DohServer->"doh-cert") ] ] do={
      :if ([ :len $DohCert ] > 0) do={
        :if ([ $CertificateAvailable $DohCert "fetch" ] = false || \
             [ $CertificateAvailable $DohCert "dns" ] = false) do={
          $LogPrint warning $ScriptName [ $Translate "netwatch-dns.certificate.failed" \
              ({ name=$DohCert }) ];
        }
      }
    }

    :local Data false;
    :onerror Err {
      :local I 1;
      :retry {
        :set I ($I ^ 1);
        :set Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
          http-header-field=({ "accept: application/dns-message" }) \
          url=(($DohServer->"doh-url") . "?dns=" . [ :convert to=base64 ([ :rndstr length=2 ] . \
          "\01\00" . "\00\01" . "\00\00" . "\00\00" . "\00\00" . "\09doh-check\05eworm" . \
          ({ "\02de"; "\03net" }->$I) . "\00" . "\00\10" . "\00\01") ]) as-value ]->"data");
      } delay=500ms max=6;
    } do={
      $LogPrint warning $ScriptName [ $Translate "netwatch-dns.request.failed" \
          ({ server=($DohServer->"doh-url"); error=$Err }) ];
      :continue;
    }

    :if ([ :typeof [ :find $Data "doh-check-OK" ] ] != "num") do={
      $LogPrint warning $ScriptName [ $Translate "netwatch-dns.response.invalid" \
          ({ server=($DohServer->"doh-url") }) ];
      :continue;
    }

    /ip/dns/set use-doh-server=($DohServer->"doh-url") verify-doh-cert=yes;
    :if ([ /certificate/settings/get crl-use ] = true) do={
      $LogPrintOnce warning $ScriptName [ $Translate "netwatch-dns.crl.warning" ];
    }
    /ip/dns/cache/flush;
    $LogPrint info $ScriptName [ $Translate "netwatch-dns.doh.setting" \
        ({ server=($DohServer->"doh-url") }) ];
    :exit;
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
