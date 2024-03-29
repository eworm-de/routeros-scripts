#!rsc by RouterOS
# RouterOS script: fw-addr-lists
# Copyright (c) 2023-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.12
#
# download, import and update firewall address-lists
# https://git.eworm.de/cgit/routeros-scripts/about/doc/fw-addr-lists.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global FwAddrLists;
  :global FwAddrListTimeOut;

  :global CertificateAvailable;
  :global EitherOr;
  :global FetchUserAgent;
  :global LogPrint;
  :global LogPrintOnce;
  :global ScriptLock;
  :global WaitFullyConnected;

  :local FindDelim do={
    :local ValidChars "0123456789.:/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-";
    :for I from=0 to=[ :len $1 ] do={
      :if ([ :typeof [ :find $ValidChars [ :pick ($1 . " ") $I ] ] ] != "num") do={
        :return $I;
      }
    }
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :error false;
  }
  $WaitFullyConnected;

  :local ListComment ("managed by " . $ScriptName);

  :foreach FwListName,FwList in=$FwAddrLists do={
    :local CntAdd 0;
    :local CntRenew 0;
    :local CntRemove 0;
    :local IPv4Addresses ({});
    :local IPv6Addresses ({});
    :local Failure false;

    :foreach List in=$FwList do={
      :local CheckCertificate "no";
      :local Data false;
      :local TimeOut [ $EitherOr [ :totime ($List->"timeout") ] $FwAddrListTimeOut ];

      :if ([ :len ($List->"cert") ] > 0) do={
        :set CheckCertificate "yes-without-crl";
        :if ([ $CertificateAvailable ($List->"cert") ] = false) do={
          $LogPrint warning $ScriptName ("Downloading required certificate failed, trying anyway.");
        }
      }

      :for I from=1 to=5 do={
        :if ($Data = false) do={
          :do {
            :set Data ([ /tool/fetch check-certificate=$CheckCertificate output=user \
              http-header-field=({ [ $FetchUserAgent $ScriptName ] }) ($List->"url") as-value ]->"data");
          } on-error={
            :if ($I < 5) do={
              $LogPrint debug $ScriptName ("Failed downloading, " . $I . ". try: " . $List->"url");
              :delay (($I * $I) . "s");
            }
          }
        }
      }

      :if ($Data = false) do={
        :set Data "";
        :set Failure true;
        $LogPrint warning $ScriptName ("Failed downloading list from: " . $List->"url");
      }

      :if ([ :len $Data ] > 63000) do={
        $LogPrintOnce warning $ScriptName ("The list is huge and may be truncated: " . $List->"url");
      }

      :while ([ :len $Data ] != 0) do={
        :local Line [ :pick $Data 0 [ :find $Data "\n" ] ];
        :local Address ([ :pick $Line 0 [ $FindDelim $Line ] ] . ($List->"cidr"));
        :if ($Address ~ "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}(/[0-9]{1,2})?\$" || \
             $Address ~ "^[\\.a-zA-Z0-9-]+\\.[a-zA-Z]{2,}\$") do={
          :set ($IPv4Addresses->$Address) $TimeOut;
        }
        :if ($Address ~ "^[0-9a-zA-Z]*:[0-9a-zA-Z:\\.]+(/[0-9]{1,3})?\$" || \
             $Address ~ "^[\\.a-zA-Z0-9-]+\\.[a-zA-Z]{2,}\$") do={
          :set ($IPv6Addresses->$Address) $TimeOut;
        }
        :set Data [ :pick $Data ([ :len $Line ] + 1) [ :len $Data ] ];
      }
    }

    :foreach Entry in=[ /ip/firewall/address-list/find where list=$FwListName comment=$ListComment ] do={
      :local Address [ /ip/firewall/address-list/get $Entry address ];
      :if ([ :typeof ($IPv4Addresses->$Address) ] = "time") do={
        $LogPrint debug $ScriptName ("Renewing IPv4 address for " . ($IPv4Addresses->$Address) . ": " . $Address);
        /ip/firewall/address-list/set $Entry timeout=($IPv4Addresses->$Address);
        :set ($IPv4Addresses->$Address);
        :set CntRenew ($CntRenew + 1);
      } else={
        :if ($Failure = false) do={
          $LogPrint debug $ScriptName ("Removing IPv4 address: " . $Address);
          /ip/firewall/address-list/remove $Entry;
          :set CntRemove ($CntRemove + 1);
        }
      }
    }

    :foreach Entry in=[ /ipv6/firewall/address-list/find where list=$FwListName comment=$ListComment ] do={
      :local Address [ /ipv6/firewall/address-list/get $Entry address ];
      :if ([ :typeof ($IPv6Addresses->$Address) ] = "time") do={
        $LogPrint debug $ScriptName ("Renewing IPv6 address for " . ($IPv6Addresses->$Address) . ": " . $Address);
        /ipv6/firewall/address-list/set $Entry timeout=($IPv6Addresses->$Address);
        :set ($IPv6Addresses->$Address);
        :set CntRenew ($CntRenew + 1);
      } else={
        :if ($Failure = false) do={
          $LogPrint debug $ScriptName ("Removing: " . $Address);
          /ipv6/firewall/address-list/remove $Entry;
          :set CntRemove ($CntRemove + 1);
        }
      }
    }

    :foreach Address,Timeout in=$IPv4Addresses do={
      $LogPrint debug $ScriptName ("Adding IPv4 address for " . $Timeout . ": " . $Address);
      :do {
        /ip/firewall/address-list/add list=$FwListName comment=$ListComment address=$Address timeout=$Timeout;
        :set ($IPv4Addresses->$Address);
        :set CntAdd ($CntAdd + 1);
      } on-error={
        $LogPrint warning $ScriptName ("Failed to add IPv4 address " . $Address . " to list '" . $FwListName . "'.");
      }
    }

    :foreach Address,Timeout in=$IPv6Addresses do={
      $LogPrint debug $ScriptName ("Adding IPv6 address for " . $Timeout . ": " . $Address);
      :do {
        /ipv6/firewall/address-list/add list=$FwListName comment=$ListComment address=$Address timeout=$Timeout;
        :set ($IPv6Addresses->$Address);
        :set CntAdd ($CntAdd + 1);
      } on-error={
        $LogPrint warning $ScriptName ("Failed to add IPv6 address " . $Address . " to list '" . $FwListName . "'.");
      }
    }

    $LogPrint info $ScriptName ("list: " . $FwListName . " -- added: " . $CntAdd . " - renewed: " . $CntRenew . " - removed: " . $CntRemove);
  }
} on-error={ }
