#!rsc by RouterOS
# RouterOS script: fw-addr-lists
# Copyright (c) 2023-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# download, import and update firewall address-lists
# https://rsc.eworm.de/doc/fw-addr-lists.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=fw-addr-lists, schema=42bcfb865c10957ae21b18aa798348228d56dea78dd75c130eee6af199b03277
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"fw-addr-lists.branch") "Handling branch: {branch}";
:set ($LanguageEnglish->"fw-addr-lists.certificate.failed") "Downloading required certificate ({list} / {url}) failed, trying anyway.";
:set ($LanguageEnglish->"fw-addr-lists.crash.delay") "Scripting subsystem may have crashed, possibly caused by us. Delaying!";
:set ($LanguageEnglish->"fw-addr-lists.download.failed") "Failed downloading for list '{list}' from: {url}";
:set ($LanguageEnglish->"fw-addr-lists.download.retry") "Failed downloading for list '{list}', {count}. try from: {url}";
:set ($LanguageEnglish->"fw-addr-lists.downloaded") "Downloaded {size}B for list '{list}' from: {url}";
:set ($LanguageEnglish->"fw-addr-lists.ipv4.add") "Adding IPv4 address {address} to list '{list}' with {timeout}.";
:set ($LanguageEnglish->"fw-addr-lists.ipv4.failed") "Failed to add IPv4 address {address} to list '{list}': {error}";
:set ($LanguageEnglish->"fw-addr-lists.ipv4.remove") "Removing IPv4 address {address} from list '{list}.";
:set ($LanguageEnglish->"fw-addr-lists.ipv4.renew") "Renewing IPv4 address {address} in list '{list}' with {timeout}.";
:set ($LanguageEnglish->"fw-addr-lists.ipv6.add") "Adding IPv6 address {address} to list '{list}' with {timeout}.";
:set ($LanguageEnglish->"fw-addr-lists.ipv6.failed") "Failed to add IPv6 address {address} to list '{list}': {error}";
:set ($LanguageEnglish->"fw-addr-lists.ipv6.remove") "Removing IPv6 address {address} from list '{list}.";
:set ($LanguageEnglish->"fw-addr-lists.ipv6.renew") "Renewing IPv6 address {address} in list '{list}' with {timeout}.";
:set ($LanguageEnglish->"fw-addr-lists.summary") "list: {list} ({total}) -- added: {added} - renewed: {renewed} - removed: {removed}";
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global FwAddrLists;
  :global FwAddrListTimeOut;
  :global LanguageEnglish;
  :global LogPrintOnceCrashMessages;

  :global CertificateAvailable;
  :global EitherOr;
  :global FetchHuge;
  :global HumanReadableNum;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global LogPrintOnce;
  :global LogPrintVerbose;
  :global NetMask4;
  :global NetMask6;
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
    :exit;
  }
  $WaitFullyConnected;

  # Include legacy English logs and messages emitted before a language change.
  :local CrashAlerts ({});
  :local EnglishAlert ($LanguageEnglish->"global-functions.log.once.crash");
  :if ([ :typeof $EnglishAlert ] = "str") do={ :set ($CrashAlerts->$EnglishAlert) true; }
  :if ([ :typeof $LogPrintOnceCrashMessages ] = "array") do={
    :foreach Alert,Unused in=$LogPrintOnceCrashMessages do={ :set ($CrashAlerts->$Alert) true; }
  }
  :local CrashDetected false;
  :foreach Alert,Unused in=$CrashAlerts do={
    :if ([ :len [ /log/find where topics=({"script"; "warning"}) \
        message=("\$LogPrintOnce: " . $Alert) ] ] > 0) do={
      :set CrashDetected true;
      :break;
    }
  }
  :if ($CrashDetected = true) do={
    $LogPrintOnce warning $ScriptName [ $Translate "fw-addr-lists.crash.delay" ];
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

      :foreach Cert in=[ :toarray delimiter=":" [ :tostr ($List->"cert") ] ] do={
        :if ([ :len ($Cert) ] > 0) do={
          :set CheckCertificate true;
          :if ([ $CertificateAvailable $Cert "fetch" ] = false) do={
            $LogPrint warning $ScriptName [ $Translate "fw-addr-lists.certificate.failed" \
                ({ list=$FwListName; url=($List->"url") }) ];
          }
        }
      }

      :for I from=1 to=5 do={
        :if ($Data = false) do={
          :set Data [ :tolf [ $FetchHuge $ScriptName ($List->"url") $CheckCertificate ] ];
          :if ($Data = false) do={
            :if ($I < 5) do={
              $LogPrint debug $ScriptName [ $Translate "fw-addr-lists.download.retry" \
                  ({ list=$FwListName; count=$I; url=($List->"url") }) ];
              :delay (($I * $I) . "s");
            }
          }
        }
      }

      :if ($Data = false) do={
        :set Data "";
        :set Failure true;
        $LogPrint warning $ScriptName [ $Translate "fw-addr-lists.download.failed" \
            ({ list=$FwListName; url=($List->"url") }) ];
      } else={
        $LogPrint debug $ScriptName [ $Translate "fw-addr-lists.downloaded" \
            ({ size=[ $HumanReadableNum [ :len $Data ] 1024 ]; list=$FwListName; url=($List->"url") }) ];
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

        :local Branch;
        :if ($Address ~ "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}(/[0-9]{1,2})?\$") do={
          :local Net $Address;
          :local CIDR 32;
          :local Slash [ :find $Address "/" ];
          :if ([ :typeof $Slash ] = "num") do={
            :set Net [ :toip [ :pick $Address 0 $Slash ] ]
            :set CIDR [ :pick $Address ($Slash + 1) [ :len $Address ] ];
            :set Address [ :tostr (([ :toip $Net ] & [ $NetMask4 $CIDR ]) . [ $IfThenElse ($CIDR < 32) ("/" . $CIDR) ]) ];
          }
          :set Branch [ $GetBranch $Address ];
          :set ($IPv4Addresses->$Branch->$Address) $TimeOut;
          :continue;
        }
        :if ($Address ~ "^[0-9a-zA-Z]*:[0-9a-zA-Z:\\.]+(/[0-9]{1,3})?\$") do={
          :local Net $Address;
          :local CIDR 128;
          :local Slash [ :find $Address "/" ];
          :if ([ :typeof $Slash ] = "num") do={
            :set Net [ :toip6 [ :pick $Address 0 $Slash ] ]
            :set CIDR [ :pick $Address ($Slash + 1) [ :len $Address ] ];
          }
          :set Address (([ :toip6 $Net ] & [ $NetMask6 $CIDR ]) . "/" . $CIDR);
          :set Branch [ $GetBranch $Address ];
          :set ($IPv6Addresses->$Branch->$Address) $TimeOut;
          :continue;
        }
        :if ($Address ~ "^[\\.a-zA-Z0-9-]+\\.[a-zA-Z]{2,}\$") do={
          :set Branch [ $GetBranch $Address ];
          :set ($IPv4Addresses->$Branch->$Address) $TimeOut;
          :set ($IPv6Addresses->$Branch->$Address) $TimeOut;
          :continue;
        }
      }
    }

    :foreach Entry in=[ /ip/firewall/address-list/find where \
        list=$FwListName comment=$ListComment ] do={
      :local Address [ /ip/firewall/address-list/get $Entry address ];
      :local Branch [ $GetBranch $Address ];
      :local TimeOut ($IPv4Addresses->$Branch->$Address);
      :if ([ :typeof $TimeOut ] = "time") do={
        $LogPrintVerbose debug $ScriptName [ $Translate "fw-addr-lists.ipv4.renew" \
            ({ address=$Address; list=$FwListName; timeout=$TimeOut }) ];
        /ip/firewall/address-list/set $Entry timeout=$TimeOut;
        :set ($IPv4Addresses->$Branch->$Address);
        :set CntRenew ($CntRenew + 1);
      } else={
        :if ($Failure = false) do={
          $LogPrintVerbose debug $ScriptName [ $Translate "fw-addr-lists.ipv4.remove" \
              ({ address=$Address; list=$FwListName }) ];
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
        $LogPrintVerbose debug $ScriptName [ $Translate "fw-addr-lists.ipv6.renew" \
            ({ address=$Address; list=$FwListName; timeout=$TimeOut }) ];
        /ipv6/firewall/address-list/set $Entry timeout=$TimeOut;
        :set ($IPv6Addresses->$Branch->$Address);
        :set CntRenew ($CntRenew + 1);
      } else={
        :if ($Failure = false) do={
          $LogPrintVerbose debug $ScriptName [ $Translate "fw-addr-lists.ipv6.remove" \
              ({ address=$Address; list=$FwListName }) ];
          /ipv6/firewall/address-list/remove $Entry;
          :set CntRemove ($CntRemove + 1);
        }
      }
    }

    :foreach BranchName,Branch in=$IPv4Addresses do={
      $LogPrintVerbose debug $ScriptName [ $Translate "fw-addr-lists.branch" \
          ({ branch=$BranchName }) ];
      :foreach Address,Timeout in=$Branch do={
        $LogPrintVerbose debug $ScriptName [ $Translate "fw-addr-lists.ipv4.add" \
            ({ address=$Address; list=$FwListName; timeout=$Timeout }) ];
        :onerror Err {
          /ip/firewall/address-list/add list=$FwListName comment=$ListComment \
              address=$Address timeout=$Timeout;
          :set CntAdd ($CntAdd + 1);
        } do={
          $LogPrint warning $ScriptName [ $Translate "fw-addr-lists.ipv4.failed" \
              ({ address=$Address; list=$FwListName; error=$Err }) ];
        }
      }
    }

    :foreach BranchName,Branch in=$IPv6Addresses do={
      $LogPrintVerbose debug $ScriptName [ $Translate "fw-addr-lists.branch" \
          ({ branch=$BranchName }) ];
      :foreach Address,Timeout in=$Branch do={
        $LogPrintVerbose debug $ScriptName [ $Translate "fw-addr-lists.ipv6.add" \
            ({ address=$Address; list=$FwListName; timeout=$Timeout }) ];
        :onerror Err {
          /ipv6/firewall/address-list/add list=$FwListName comment=$ListComment \
              address=$Address timeout=$Timeout;
          :set CntAdd ($CntAdd + 1);
        } do={
          $LogPrint warning $ScriptName [ $Translate "fw-addr-lists.ipv6.failed" \
              ({ address=$Address; list=$FwListName; error=$Err }) ];
        }
      }
    }

    $LogPrint info $ScriptName [ $Translate "fw-addr-lists.summary" \
        ({ list=$FwListName; total=[ $HumanReadableNum ($CntAdd + $CntRenew) 1000 ]; added=[ $HumanReadableNum $CntAdd 1000 ]; renewed=[ $HumanReadableNum $CntRenew 1000 ]; removed=[ $HumanReadableNum $CntRemove 1000 ] }) ];
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
