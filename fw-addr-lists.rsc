#!rsc by RouterOS
# RouterOS script: fw-addr-lists
# Copyright (c) 2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# download, import and update firewall address-lists
# https://git.eworm.de/cgit/routeros-scripts/about/doc/fw-addr-lists.md

:local 0 "fw-addr-lists";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global FwAddrLists;
:global FwAddrListTimeOut;

:global CertificateAvailable;
:global LogPrintExit2;
:global ScriptLock;
:global WaitFullyConnected;

:local FindDelim do={
  :local ValidChars "0123456789./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-";
  :for I from=0 to=[ :len $1 ] do={
    :if ([ :typeof [ :find $ValidChars [ :pick ($1 . " ") $I ] ] ] != "num") do={
      :return $I;
    }
  }
}

$ScriptLock $0;
$WaitFullyConnected;

:local ListComment ("managed by " . $0);

:foreach FwListName,FwList in=$FwAddrLists do={
  :local Addresses ({});
  :local CntAdd 0;
  :local CntRenew 0;
  :local CntRemove 0;
  :local Failure false;

  :foreach List in=$FwList do={
    :local CheckCertificate "no";
    :local Data false;

    :if ([ :len ($List->"cert") ] > 0) do={
      :set CheckCertificate "yes-without-crl";
      :if ([ $CertificateAvailable ($List->"cert") ] = false) do={
        $LogPrintExit2 warning $0 ("Downloading required certificate failed, trying anyway.") false;
      }
    }

    :for I from=2 to=0 do={
      :if ($Data = false) do={
        :do {
          :set Data ([ /tool/fetch ($List->"url") check-certificate=$CheckCertificate output=user as-value ]->"data");
        } on-error={
          $LogPrintExit2 debug $0 ("Failed downloading, " . $I . " retries pending: " . $List->"url") false;
          :delay 2s;
        }
      }
    }

    :if ($Data = false) do={
      :set Data "";
      :set Failure true;
      $LogPrintExit2 warning $0 ("Failed downloading list from: " . $List->"url") false;
    }

    :while ([ :len $Data ] != 0) do={
      :local Line [ :pick $Data 0 [ :find $Data "\n" ] ];
      :local Address ([ :pick $Line 0 [ $FindDelim $Line ] ] . ($List->"cidr"));
      :if ($Address ~ "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}(/[0-9]{1,2})?\$" || \
           $Address ~ "^[\\.a-zA-Z0-9-]+\\.[a-zA-Z]{2,}\$") do={
        :set ($Addresses->$Address) 1;
      }
      :set Data [ :pick $Data ([ :len $Line ] + 1) [ :len $Data ] ];
    }
  }

  :foreach Entry in=[ /ip/firewall/address-list/find where list=$FwListName comment=$ListComment ] do={
    :local Address [ /ip/firewall/address-list/get $Entry address ];
    :if (($Addresses->$Address) = 1) do={
      $LogPrintExit2 debug $0 ("Renewing: " . $Address) false;
      /ip/firewall/address-list/set $Entry timeout=$FwAddrListTimeOut;
      :set ($Addresses->$Address);
      :set CntRenew ($CntRenew + 1);
    } else={
      :if ($Failure = false) do={
        $LogPrintExit2 debug $0 ("Removing: " . $Address) false;
        /ip/firewall/address-list/remove $Entry;
        :set CntRemove ($CntRemove + 1);
      }
    }
  }

  :foreach Address,Ignore in=$Addresses do={
    $LogPrintExit2 debug $0 ("Adding: " . $Address) false;
    :do {
      /ip/firewall/address-list/add list=$FwListName comment=$ListComment address=$Address timeout=$FwAddrListTimeOut;
      :set ($Addresses->$Address);
      :set CntAdd ($CntAdd + 1);
    } on-error={
      $LogPrintExit2 warning $0 ("Failed to add address " . $Address . " to list '" . $FwListName . "'.") false;
    }
  }

  $LogPrintExit2 info $0 ("list: " . $FwListName . " -- added: " . $CntAdd . " - renewed: " . $CntRenew . " - removed: " . $CntRemove) false;
}
