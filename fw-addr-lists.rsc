#!rsc by RouterOS
# RouterOS script: fw-addr-lists
# Copyright (c) 2023-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.16
#
# download, import and update firewall address-lists
# https://git.eworm.de/cgit/routeros-scripts/about/doc/fw-addr-lists.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local ExitOK false;
:do {
  :local ScriptName [ :jobname ];

  :global FwAddrLists;
  :global FwAddrListTimeOut;

  :global CertificateAvailable;
  :global EitherOr;
  :global FetchHuge;
  :global HumanReadableNum;
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
    :set ExitOK true;
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
      :local CheckCertificate false;
      :local Data false;
      :local TimeOut [ $EitherOr [ :totime ($List->"timeout") ] $FwAddrListTimeOut ];

      :if ([ :len ($List->"cert") ] > 0) do={
        :set CheckCertificate true;
        :if ([ $CertificateAvailable ($List->"cert") ] = false) do={
          $LogPrint warning $ScriptName ("Downloading required certificate (" . $FwListName . \
              " / " . $List->"url" . ") failed, trying anyway.");
        }
      }

      :for I from=1 to=5 do={
        :if ($Data = false) do={
          :set Data [ :tolf [ $FetchHuge $ScriptName ($List->"url") $CheckCertificate ] ];
          :if ($Data = false) do={
            :if ($I < 5) do={
              $LogPrint debug $ScriptName ("Failed downloading for list '" . $FwListName . \
                  "', " . $I . ". try from: " . $List->"url");
              :delay (($I * $I) . "s");
            }
          }
        }
      }

      :if ($Data = false) do={
        :set Data "";
        :set Failure true;
        $LogPrint warning $ScriptName ("Failed downloading for list '" . $FwListName . \
            "' from: " . $List->"url");
      } else={
        $LogPrint debug $ScriptName ("Downloaded " . [ $HumanReadableNum [ :len $Data ] 1024 ] . \
            "B for list '" . $FwListName . "' from: " . $List->"url");
      }

      :foreach Line in=[ :deserialize $Data delimiter="\n" from=dsv options=dsv.plain ] do={
        :set Line ($Line->0);
        :local Address;
        :if ([ :pick $Line 0 1 ] = "{") do={
          :do {
            :set Address [ :tostr ([ :deserialize from=json $Line ]->"cidr") ];
          } on-error={ }
        } else={
          :set Address ([ :pick $Line 0 [ $FindDelim $Line ] ] . ($List->"cidr"));
        }
        :do {
          :if ($Address ~ "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}(/[0-9]{1,2})?\$") do={
            :set ($IPv4Addresses->$Address) $TimeOut;
            :error true;
          }
          :if ($Address ~ "^[0-9a-zA-Z]*:[0-9a-zA-Z:\\.]+(/[0-9]{1,3})?\$") do={
            :set ($IPv6Addresses->$Address) $TimeOut;
            :error true;
          }
          :if ($Address ~ "^[\\.a-zA-Z0-9-]+\\.[a-zA-Z]{2,}\$") do={
            :set ($IPv4Addresses->$Address) $TimeOut;
            :set ($IPv6Addresses->$Address) $TimeOut;
            :error true;
          }
        } on-error={ }
      }
    }

    :foreach Entry in=[ /ip/firewall/address-list/find where \
        list=$FwListName comment=$ListComment ] do={
      :local Address [ /ip/firewall/address-list/get $Entry address ];
      :if ([ :typeof ($IPv4Addresses->$Address) ] = "time") do={
        $LogPrint debug $ScriptName ("Renewing IPv4 address in list '" . $FwListName . \
            "' with " . ($IPv4Addresses->$Address) . ": " . $Address);
        /ip/firewall/address-list/set $Entry timeout=($IPv4Addresses->$Address);
        :set ($IPv4Addresses->$Address);
        :set CntRenew ($CntRenew + 1);
      } else={
        :if ($Failure = false) do={
          $LogPrint debug $ScriptName ("Removing IPv4 address from list '" . $FwListName . \
              "': " . $Address);
          /ip/firewall/address-list/remove $Entry;
          :set CntRemove ($CntRemove + 1);
        }
      }
    }

    :foreach Entry in=[ /ipv6/firewall/address-list/find where \
        list=$FwListName comment=$ListComment ] do={
      :local Address [ /ipv6/firewall/address-list/get $Entry address ];
      :if ([ :typeof ($IPv6Addresses->$Address) ] = "time") do={
        $LogPrint debug $ScriptName ("Renewing IPv6 address in list '" . $FwListName . \
            "' with " . ($IPv6Addresses->$Address) . ": " . $Address);
        /ipv6/firewall/address-list/set $Entry timeout=($IPv6Addresses->$Address);
        :set ($IPv6Addresses->$Address);
        :set CntRenew ($CntRenew + 1);
      } else={
        :if ($Failure = false) do={
          $LogPrint debug $ScriptName ("Removing IPv6 address from list '" . $FwListName . \
              "': " . $Address);
          /ipv6/firewall/address-list/remove $Entry;
          :set CntRemove ($CntRemove + 1);
        }
      }
    }

    :foreach Address,Timeout in=$IPv4Addresses do={
      $LogPrint debug $ScriptName ("Adding IPv4 address to list '" . $FwListName . \
          "' with " . $Timeout . ": " . $Address);
      :do {
        /ip/firewall/address-list/add list=$FwListName comment=$ListComment \
            address=$Address timeout=$Timeout;
        :set ($IPv4Addresses->$Address);
        :set CntAdd ($CntAdd + 1);
      } on-error={
        $LogPrint warning $ScriptName ("Failed to add IPv4 address to list '" . $FwListName . \
            "': " . $Address);
      }
    }

    :foreach Address,Timeout in=$IPv6Addresses do={
      $LogPrint debug $ScriptName ("Adding IPv6 address to list '" . $FwListName . \
          "' with " . $Timeout . ": " . $Address);
      :do {
        /ipv6/firewall/address-list/add list=$FwListName comment=$ListComment \
            address=$Address timeout=$Timeout;
        :set ($IPv6Addresses->$Address);
        :set CntAdd ($CntAdd + 1);
      } on-error={
        $LogPrint warning $ScriptName ("Failed to add IPv6 address to list '" . $FwListName . \
            "': " . $Address);
      }
    }

    $LogPrint info $ScriptName ("list: " . $FwListName . \
        " (" . [ $HumanReadableNum ($CntAdd + $CntRenew) 1000 ] . ")" . \
        " -- added: " . [ $HumanReadableNum $CntAdd 1000 ] . \
        " - renewed: " . [ $HumanReadableNum $CntRenew 1000 ] . \
        " - removed: " . [ $HumanReadableNum $CntRemove 1000 ]);
  }
} on-error={
  :global ExitError; $ExitError $ExitOK [ :jobname ];
}
