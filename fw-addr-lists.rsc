#!rsc by RouterOS
# RouterOS script: fw-addr-lists
# Copyright (c) 2023-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.16
#
# download, import and update firewall address-lists
# https://rsc.eworm.de/doc/fw-addr-lists.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global FwAddrLists;
  :global FwAddrListTimeOut;

  :global CertificateAvailable;
  :global EitherOr;
  :global FetchHuge;
  :global HumanReadableNum;
  :global LogPrint;
  :global LogPrintOnce;
  :global LogPrintVerbose;
  :global MIN;
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

  :local GetBranch do={
    :global EitherOr;
    :return [ :pick [ :convert transform=md5 to=hex [ :pick $1 0 [ $EitherOr [ :find $1 "/" ] [ :len $1 ] ] ] ] 0 2 ];
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }
  $WaitFullyConnected;

  :if ([ :len [ /log/find where topics=({"script"; "warning"}) \
      message=("\$LogPrintOnce: The message is already in log, scripting subsystem may have crashed before!") ] ] > 0) do={
    $LogPrintOnce warning $ScriptName ("Scripting subsystem may have crashed, possibly caused by us. Delaying!");
    :delay 5m;
  }

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
        :if ([ :pick $Line 0 1 ] = "{" && [ :pick $Line ([ :len $Line ] - 1) ] = "}") do={
          :do {
            :set Address [ :tostr ([ :deserialize from=json $Line ]->"cidr") ];
          } on-error={ }
        } else={
          :set Address ([ :pick $Line 0 [ $FindDelim $Line ] ] . ($List->"cidr"));
        }
        :do {
          :local Branch [ $GetBranch $Address ];
          :if ($Address ~ "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}(/[0-9]{1,2})?\$") do={
            :if ($Address ~ "/32\$") do={
              :set Address [ :pick $Address 0 ([ :len $Address ] - 3) ];
            }
            :set ($IPv4Addresses->$Branch->$Address) $TimeOut;
            :error true;
          }
          :if ($Address ~ "^[0-9a-zA-Z]*:[0-9a-zA-Z:\\.]+(/[0-9]{1,3})?\$") do={
            :local Net $Address;
            :local Cidr 64;
            :local Slash [ :find $Address "/" ];
            :if ([ :typeof $Slash ] = "num") do={
              :set Net [ :toip6 [ :pick $Address 0 $Slash ] ]
              :set Cidr [ $MIN [ :pick $Address ($Slash + 1) [ :len $Address ] ] 64 ];
            }
            :set Address (([ :toip6 $Net ] & ffff:ffff:ffff:ffff::) . "/" . $Cidr);
            :set ($IPv6Addresses->$Branch->$Address) $TimeOut;
            :error true;
          }
          :if ($Address ~ "^[\\.a-zA-Z0-9-]+\\.[a-zA-Z]{2,}\$") do={
            :set ($IPv4Addresses->$Branch->$Address) $TimeOut;
            :set ($IPv6Addresses->$Branch->$Address) $TimeOut;
            :error true;
          }
        } on-error={ }
      }
    }

    :foreach Entry in=[ /ip/firewall/address-list/find where \
        list=$FwListName comment=$ListComment ] do={
      :local Address [ /ip/firewall/address-list/get $Entry address ];
      :local Branch [ $GetBranch $Address ];
      :local TimeOut ($IPv4Addresses->$Branch->$Address);
      :if ([ :typeof $TimeOut ] = "time") do={
        $LogPrintVerbose debug $ScriptName ("Renewing IPv4 address " . $Address . \
            " in list '" . $FwListName . "' with " . $TimeOut . ".");
        /ip/firewall/address-list/set $Entry timeout=$TimeOut;
        :set ($IPv4Addresses->$Branch->$Address);
        :set CntRenew ($CntRenew + 1);
      } else={
        :if ($Failure = false) do={
          $LogPrintVerbose debug $ScriptName ("Removing IPv4 address " . $Address . \
              " from list '" . $FwListName . ".");
          /ip/firewall/address-list/remove $Entry;
          :set CntRemove ($CntRemove + 1);
        }
      }
    }

    :foreach Entry in=[ /ipv6/firewall/address-list/find where \
        list=$FwListName comment=$ListComment ] do={
      :local Address [ /ipv6/firewall/address-list/get $Entry address ];
      :local Branch [ $GetBranch $Address ];
      :local TimeOut ($IPv6Addresses->$Branch->$Address);
      :if ([ :typeof $TimeOut ] = "time") do={
        $LogPrintVerbose debug $ScriptName ("Renewing IPv6 address " . $Address . \
            " in list '" . $FwListName . "' with " . $TimeOut . ".");
        /ipv6/firewall/address-list/set $Entry timeout=$TimeOut;
        :set ($IPv6Addresses->$Branch->$Address);
        :set CntRenew ($CntRenew + 1);
      } else={
        :if ($Failure = false) do={
          $LogPrintVerbose debug $ScriptName ("Removing IPv6 address " . $Address . \
              " from list '" . $FwListName .".");
          /ipv6/firewall/address-list/remove $Entry;
          :set CntRemove ($CntRemove + 1);
        }
      }
    }

    :foreach BranchName,Branch in=$IPv4Addresses do={
      $LogPrintVerbose debug $ScriptName ("Handling branch: " . $BranchName);
      :foreach Address,Timeout in=$Branch do={
        $LogPrintVerbose debug $ScriptName ("Adding IPv4 address " . $Address . \
            " to list '" . $FwListName . "' with " . $Timeout . ".");
        :onerror Err {
          /ip/firewall/address-list/add list=$FwListName comment=$ListComment \
              address=$Address timeout=$Timeout;
          :set CntAdd ($CntAdd + 1);
        } do={
          $LogPrint warning $ScriptName ("Failed to add IPv4 address " . $Address . \
              " to list '" . $FwListName . "': " . $Err);
        }
      }
    }

    :foreach BranchName,Branch in=$IPv6Addresses do={
      $LogPrintVerbose debug $ScriptName ("Handling branch: " . $BranchName);
      :foreach Address,Timeout in=$Branch do={
        $LogPrintVerbose debug $ScriptName ("Adding IPv6 address " . $Address . \
            " to list '" . $FwListName . "' with " . $Timeout . ".");
        :onerror Err {
          /ipv6/firewall/address-list/add list=$FwListName comment=$ListComment \
              address=$Address timeout=$Timeout;
          :set CntAdd ($CntAdd + 1);
        } do={
          $LogPrint warning $ScriptName ("Failed to add IPv6 address " . $Address . \
              " to list '" . $FwListName . "': " . $Err);
        }
      }
    }

    $LogPrint info $ScriptName ("list: " . $FwListName . \
        " (" . [ $HumanReadableNum ($CntAdd + $CntRenew) 1000 ] . ")" . \
        " -- added: " . [ $HumanReadableNum $CntAdd 1000 ] . \
        " - renewed: " . [ $HumanReadableNum $CntRenew 1000 ] . \
        " - removed: " . [ $HumanReadableNum $CntRemove 1000 ]);
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
