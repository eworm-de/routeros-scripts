#!rsc by RouterOS
# RouterOS script: global-functions
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.10beta5
#
# global functions
# https://git.eworm.de/cgit/routeros-scripts/about/

:local 0 "global-functions";

# expected configuration version
:global ExpectedConfigVersion 111;

# global variables not to be changed by user
:global GlobalFunctionsReady false;
:global FetchUserAgent ("User-Agent: Mikrotik/" . [ /system/resource/get version ] . " Fetch");
:global Identity [ /system/identity/get name ];

# global functions
:global CertificateAvailable;
:global CertificateDownload;
:global CertificateNameByCN;
:global CharacterReplace;
:global CleanFilePath;
:global DeviceInfo;
:global Dos2Unix;
:global DownloadPackage;
:global EitherOr;
:global EscapeForRegEx;
:global FormatLine;
:global FormatMultiLines;
:global GetMacVendor;
:global GetRandom20CharAlNum;
:global GetRandom20CharHex;
:global GetRandomNumber;
:global Grep;
:global HexToNum;
:global IfThenElse;
:global IsDefaultRouteReachable;
:global IsDNSResolving;
:global IsFullyConnected;
:global IsMacLocallyAdministered;
:global IsTimeSync;
:global LogPrintExit2;
:global LogPrintOnce;
:global MkDir;
:global NotificationFunctions;
:global ParseDate;
:global ParseJson;
:global ParseKeyValueStore;
:global PrettyPrint;
:global RandomDelay;
:global Read;
:global RequiredRouterOS;
:global ScriptFromTerminal;
:global ScriptInstallUpdate;
:global ScriptLock;
:global SendNotification;
:global SendNotification2;
:global SymbolByUnicodeName;
:global SymbolForNotification;
:global Unix2Dos;
:global UrlEncode;
:global ValidateSyntax;
:global VersionToNum;
:global WaitDefaultRouteReachable;
:global WaitDNSResolving;
:global WaitForFile;
:global WaitFullyConnected;
:global WaitTimeSync;

# check and download required certificate
:set CertificateAvailable do={
  :local CommonName [ :tostr $1 ];

  :global CertificateDownload;
  :global LogPrintExit2;
  :global ParseKeyValueStore;

  :if ([ /system/resource/get free-hdd-space ] < 8388608 && \
       [ /certificate/settings/get crl-download ] = true && \
       [ /certificate/settings/get crl-store ] = "system") do={
    $LogPrintExit2 warning $0 ("This system has low free flash space but " . \
      "is configured to download certificate CRLs to system!") false;
  }

  :if ([ :len [ /certificate/find where common-name=$CommonName ] ] = 0) do={
    $LogPrintExit2 info $0 ("Certificate with CommonName \"" . $CommonName . "\" not available.") false;
    :if ([ $CertificateDownload $CommonName ] = false) do={
      :return false;
    }
  }

  :local CertVal [ /certificate/get [ find where common-name=$CommonName ] ];
  :while (($CertVal->"akid") != "" && ($CertVal->"akid") != ($CertVal->"skid")) do={
    :if ([ :len [ /certificate/find where skid=($CertVal->"akid") ] ] = 0) do={
      $LogPrintExit2 info $0 ("Certificate chain for \"" . $CommonName . \
        "\" is incomplete, missing \"" . ([ $ParseKeyValueStore ($CertVal->"issuer") ]->"CN") . "\".") false;
      :if ([ $CertificateDownload $CommonName ] = false) do={
        :return false;
      }
    }
    :set CertVal [ /certificate/get [ find where skid=($CertVal->"akid") ] ];
  }
  :return true;
}

# download and import certificate
:set CertificateDownload do={
  :local CommonName [ :tostr $1 ];

  :global FetchUserAgent;
  :global ScriptUpdatesBaseUrl;
  :global ScriptUpdatesUrlSuffix;

  :global CertificateNameByCN;
  :global LogPrintExit2;
  :global UrlEncode;
  :global WaitForFile;

  $LogPrintExit2 info $0 ("Downloading and importing certificate with " . \
      "CommonName \"" . $CommonName . "\".") false;
  :do {
    :local LocalFileName ($CommonName . ".pem");
    :local UrlFileName ([ $UrlEncode $CommonName ] . ".pem");
    /tool/fetch check-certificate=yes-without-crl http-header-field=({ $FetchUserAgent }) \
      ($ScriptUpdatesBaseUrl . "certs/" . $UrlFileName . $ScriptUpdatesUrlSuffix) \
      dst-path=$LocalFileName as-value;
    $WaitForFile $LocalFileName;
    /certificate/import file-name=$LocalFileName passphrase="" as-value;
    /file/remove $LocalFileName;

    :foreach Cert in=[ /certificate/find where name~("^" . $LocalFileName . "_[0-9]+\$") ] do={
      $CertificateNameByCN [ /certificate/get $Cert common-name ];
    }
  } on-error={
    $LogPrintExit2 warning $0 ("Failed importing certificate with " . \
        "CommonName \"" . $CommonName . "\"!") false;
    :return false;
  }
  :delay 1s;
  :return true;
}

# name a certificate by its common-name
:set CertificateNameByCN do={
  :local CommonName [ :tostr $1 ];

  :global CharacterReplace;

  :local Cert [ /certificate/find where common-name=$CommonName ];
  /certificate/set $Cert \
    name=[ $CharacterReplace [ $CharacterReplace [ $CharacterReplace $CommonName "'" "-" ] " " "-" ] "---" "-" ];
}

# character replace
:set CharacterReplace do={
  :local String [ :tostr $1 ];
  :local ReplaceFrom [ :tostr $2 ];
  :local ReplaceWith [ :tostr $3 ];
  :local Return "";

  :if ($ReplaceFrom = "") do={
    :return $String;
  }

  :while ([ :typeof [ :find $String $ReplaceFrom ] ] != "nil") do={
    :local Pos [ :find $String $ReplaceFrom ];
    :set Return ($Return . [ :pick $String 0 $Pos ] . $ReplaceWith);
    :set String [ :pick $String ($Pos + [ :len $ReplaceFrom ]) [ :len $String ] ];
  }

  :return ($Return . $String);
}

# clean file path
:set CleanFilePath do={
  :local Path [ :tostr $1 ];

  :global CharacterReplace;

  :while ($Path ~ "//") do={
    :set $Path [ $CharacterReplace $Path "//" "/" ];
  }
  :if ([ :pick $Path 0 ] = "/") do={
    :set Path [ :pick $Path 1 [ :len $Path ] ];
  }
  :if ([ :pick $Path ([ :len $Path ] - 1) ] = "/") do={
    :set Path [ :pick $Path 0 ([ :len $Path ] - 1) ];
  }

  :return $Path;
}

# get readable device info
:set DeviceInfo do={
  :global ExpectedConfigVersion;
  :global Identity;

  :global IfThenElse;
  :global FormatLine;

  :local Resource [ /system/resource/get ];
  :local RouterBoard;
  :do {
    :set RouterBoard [[ :parse "/system/routerboard/get" ]];
  } on-error={ }
  :local License [ /system/license/get ];
  :local Update [ /system/package/update/get ];

  :return ( \
    [ $FormatLine "Hostname" $Identity ] . "\n" . \
    [ $FormatLine "Board name" ($Resource->"board-name") ] . "\n" . \
    [ $FormatLine "Architecture" ($Resource->"architecture-name") ] . "\n" . \
    [ $IfThenElse ($RouterBoard->"routerboard" = true) \
      ([ $FormatLine "Model" ($RouterBoard->"model") ] . \
       [ $IfThenElse ([ :len ($RouterBoard->"revision") ] > 0) \
           (" " . $RouterBoard->"revision") ] . "\n" . \
       [ $FormatLine "Serial number" ($RouterBoard->"serial-number") ] . "\n") ] . \
    [ $IfThenElse ([ :len ($License->"level") ] > 0) \
      ([ $FormatLine "License" ($License->"level") ] . "\n") ] . \
    "RouterOS:\n" . \
    [ $FormatLine "    Channel" ($Update->"channel") ] . "\n" . \
    [ $FormatLine "    Installed" ($Update->"installed-version") ] . "\n" . \
    [ $IfThenElse ([ :typeof ($Update->"latest-version") ] != "nothing" && \
        $Update->"installed-version" != $Update->"latest-version") \
      ([ $FormatLine "    Available" ($Update->"latest-version") ] . "\n") ] . \
    [ $IfThenElse ($RouterBoard->"routerboard" = true && \
        $RouterBoard->"current-firmware" != $RouterBoard->"upgrade-firmware") \
      ([ $FormatLine "    Firmware" ($RouterBoard->"current-firmware") ] . "\n") ] . \
    "RouterOS-Scripts:\n" . \
    [ $FormatLine "    Version" $ExpectedConfigVersion ]);
}

# convert line endings, DOS -> UNIX
:set Dos2Unix do={
  :local Input [ :tostr $1 ];

  :global CharacterReplace;

  :return [ $CharacterReplace $Input ("\r\n") ("\n") ];
}

# download package from upgrade server
:set DownloadPackage do={
  :local PkgName [ :tostr $1 ];
  :local PkgVer  [ :tostr $2 ];
  :local PkgArch [ :tostr $3 ];
  :local PkgDir  [ :tostr $4 ];

  :global CertificateAvailable;
  :global CleanFilePath;
  :global LogPrintExit2;
  :global MkDir;
  :global WaitForFile;

  :if ([ :len $PkgName ] = 0) do={ :return false; }
  :if ([ :len $PkgVer  ] = 0) do={ :set PkgVer  [ /system/package/update/get installed-version ]; }
  :if ([ :len $PkgArch ] = 0) do={ :set PkgArch [ /system/resource/get architecture-name ]; }

  :if ($PkgName = "system") do={ :set PkgName "routeros"; }

  :local PkgFile ($PkgName . "-" . $PkgVer . "-" . $PkgArch . ".npk");
  :if ($PkgArch = "x86_64") do={ :set PkgFile ($PkgName . "-" . $PkgVer . ".npk"); }
  :local PkgDest [ $CleanFilePath ($PkgDir . "/" . $PkgFile) ];

  :if ([ $MkDir $PkgDir ] = false) do={
    $LogPrintExit2 warning $0 ("Failed creating directory, not downloading package.") false;
    :return false;
  }

  :if ([ :len [ /file/find where name=$PkgDest type="package" ] ] > 0) do={
    $LogPrintExit2 info $0 ("Package file " . $PkgName . " already exists.") false;
    :return true;
  }

  :if ([ $CertificateAvailable "R3" ] = false) do={
    $LogPrintExit2 error $0 ("Downloading required certificate failed.") true;
  }

  :local Url ("https://upgrade.mikrotik.com/routeros/" . $PkgVer . "/" . $PkgFile);
  $LogPrintExit2 info $0 ("Downloading package file '" . $PkgName . "'...") false;
  $LogPrintExit2 debug $0 ("... from url: " . $Url) false;
  :local Retry 3;
  :while ($Retry > 0) do={
    :do {
      /tool/fetch check-certificate=yes-without-crl $Url dst-path=$PkgDest;
      $WaitForFile $PkgDest;

      :if ([ /file/get [ find where name=$PkgDest ] type ] = "package") do={
        :return true;
      }
    } on-error={
      $LogPrintExit2 debug $0 ("Downloading package file failed.") false;
    }

    /file/remove [ find where name=$PkgDest ];
    :set Retry ($Retry - 1);
  }

  $LogPrintExit2 warning $0 ("Downloading package file '" . $PkgName . "' failed.") false;
  :return false;
}

# return either first (if "true") or second
:set EitherOr do={
  :global IfThenElse;

  :if ([ :typeof $1 ] = "num") do={
    :return [ $IfThenElse ($1 != 0) $1 $2 ];
  }
  :if ([ :typeof $1 ] = "time") do={
    :return [ $IfThenElse ($1 > 0s) $1 $2 ];
  }
  :return [ $IfThenElse ([ :len [ :tostr $1 ] ] > 0) $1 $2 ];
}

# escape for regular expression
:set EscapeForRegEx do={
  :local Input [ :tostr $1 ];

  :if ([ :len $Input ] = 0) do={
    :return "";
  }

  :local Return "";
  :local Chars ("^.[]\$()|*+?{}\\");

  :for I from=0 to=([ :len $Input ] - 1) do={
    :local Char [ :pick $Input $I ];
    :if ([ :find $Chars $Char ]) do={
      :set Char ("\\" . $Char);
    }
    :set Return ($Return . $Char);
  }

  :return $Return;
}

# format a line for output
:set FormatLine do={
  :local Key    [ :tostr $1 ];
  :local Value  [ :tostr $2 ];
  :local Indent [ :tonum $3 ];
  :local Spaces "                ";
  :local Return "";

  :global EitherOr;

  :set Indent [ $EitherOr $Indent 16 ];

  :if ([ :len $Key ] > 0) do={ :set Return ($Key . ":"); }
  :if ([ :len $Key ] > ($Indent - 2)) do={
    :set Return ($Return . "\n" . [ :pick $Spaces 0 $Indent ] . $Value);
  } else={
    :set Return ($Return . [ :pick $Spaces 0 ($Indent - [ :len $Return ]) ] . $Value);
  }

  :return $Return;
}

# format multiple lines for output
:set FormatMultiLines do={
  :local Key    [ :tostr   $1 ];
  :local Values [ :toarray $2 ];
  :local Indent [ :tonum   $3 ];
  :local Return;

  :global FormatLine;

  :set Return [ $FormatLine $Key ($Values->0) $Indent ];
  :foreach Value in=[ :pick $Values 1 [ :len $Values ] ] do={
    :set Return ($Return . "\n" . [ $FormatLine "" $Value $Indent ]);
  }

  :return $Return;
}

# get MAC vendor
:set GetMacVendor do={
  :local Mac [ :tostr $1 ];

  :global CertificateAvailable;
  :global IsMacLocallyAdministered;
  :global LogPrintExit2;

  :if ([ $IsMacLocallyAdministered $Mac ] = true) do={
    :return "locally administered";
  }

  :do {
    :if ([ $CertificateAvailable "R3" ] = false) do={
      $LogPrintExit2 warning $0 ("Downloading required certificate failed.") true;
    }
    :local Vendor ([ /tool/fetch check-certificate=yes-without-crl \
        ("https://api.macvendors.com/" . [ :pick $Mac 0 8 ]) output=user as-value ]->"data");
    :return $Vendor;
  } on-error={
    :do {
      /tool/fetch check-certificate=yes-without-crl ("https://api.macvendors.com/") \
        output=none as-value;
      $LogPrintExit2 debug $0 ("The mac vendor is not known in database.") false;
    } on-error={
      $LogPrintExit2 warning $0 ("Failed getting mac vendor.") false;
    }
    :return "unknown vendor";
  }
}

# generate random 20 chars alphabetical (A-Z & a-z) and numerical (0-9)
:set GetRandom20CharAlNum do={
  :global EitherOr;

  :return [ :rndstr length=[ $EitherOr [ :tonum $1 ] 20 ] from="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ];
}

# generate random 20 chars hex (0-9 and a-f)
:set GetRandom20CharHex do={
  :global EitherOr;

  :return [ :rndstr length=[ $EitherOr [ :tonum $1 ] 20 ] from="0123456789abcdef" ];
}

# generate random number
:set GetRandomNumber do={
  :global EitherOr;

  :return [ :rndnum from=0 to=[ $EitherOr [ :tonum $1 ] 4294967295 ] ];
}

# return first line that matches a pattern
:set Grep do={
  :local Input  ([ :tostr $1 ] . "\n");
  :local Pattern [ :tostr $2 ];

  :if ([ :typeof [ :find $Input $Pattern ] ] = "nil") do={
    :return [];
  }

  :do {
    :local Line [ :pick $Input 0 [ :find $Input "\n" ] ];
    :if ([ :typeof [ :find $Line $Pattern ] ] = "num") do={
      :return $Line;
    }
    :set Input [ :pick $Input ([ :find $Input "\n" ] + 1) [ :len $Input ] ];
  } while=([ :len $Input ] > 0);

  :return [];
}

# convert from hex (string) to num
:set HexToNum do={
  :local Input [ :tostr $1 ];
  :local Hex "0123456789abcdef0123456789ABCDEF";
  :local Multi 1;
  :local Return 0;

  :for I from=([ :len $Input ] - 1) to=0 do={
    :set Return ($Return + (([ :find $Hex [ :pick $Input $I ] ] % 16) * $Multi));
    :set Multi ($Multi * 16);
  }

  :return $Return;
}

# mimic conditional/ternary operator (condition ? consequent : alternative)
:set IfThenElse do={
  :if ([ :tostr $1 ] = "true" || [ :tobool $1 ] = true) do={
    :return $2;
  }
  :return $3;
}

# check if default route is reachable
:set IsDefaultRouteReachable do={
  :if ([ :len [ /ip/route/find where dst-address=0.0.0.0/0 active routing-table=main ] ] > 0) do={
    :return true;
  }
  :return false;
}

# check if DNS is resolving
:set IsDNSResolving do={
  :global CharacterReplace;

  :do {
    :resolve "low-ttl.eworm.de";
  } on-error={
    :return false;
  }
  :return true;
}

# check if system is is fully connected (default route reachable, DNS resolving, time sync)
:set IsFullyConnected do={
  :global IsDefaultRouteReachable;
  :global IsDNSResolving;
  :global IsTimeSync;

  :if ([ $IsDefaultRouteReachable ] = false) do={
    :return false;
  }
  :if ([ $IsDNSResolving ] = false) do={
    :return false;
  }
  :if ([ $IsTimeSync ] = false) do={
    :return false;
  }
  :return true;
}

# check if mac address is locally administered
:set IsMacLocallyAdministered do={
  :if ([ :tonum ("0x" . [ :pick $1 0 [ :find $1 ":" ] ]) ] & 2 = 2) do={
    :return true;
  }
  :return false;
}

# check if system time is sync
:set IsTimeSync do={
  :global IsTimeSyncCached;
  :global IsTimeSyncResetNtp;

  :global LogPrintExit2;

  :if ($IsTimeSyncCached = true) do={
    :return true;
  }

  :if ([ /system/ntp/client/get enabled ] = true) do={
    :if ([ /system/ntp/client/get status ] = "synchronized") do={
      :set IsTimeSyncCached true;
      :return true;
    }

    :if ([ :typeof $IsTimeSyncResetNtp ] = "nothing") do={
      :set IsTimeSyncResetNtp 0s;
    }
    :local Uptime [ /system/resource/get uptime ];
    :if ($Uptime - $IsTimeSyncResetNtp < 3m) do={
      :return false;
    }

    :set IsTimeSyncResetNtp $Uptime;
    /system/ntp/client/set enabled=no;
    :delay 20ms;
    /system/ntp/client/set enabled=yes;
    :return false;
  }

  :if ([ /system/license/get ]->"level" = "free" || \
       [ /system/resource/get ]->"board-name" = "x86") do={
    $LogPrintExit2 debug $0 ("No ntp client configured, relying on RTC for CHR free license and x86.") false;
    :return true;
  }

  :if ([ /ip/cloud/get update-time ] = true) do={
    :if ([ :typeof [ /ip/cloud/get public-address ] ] = "ip") do={
      :set IsTimeSyncCached true;
      :return true;
    }
    :return false;
  }

  $LogPrintExit2 debug $0 ("No time source configured! Returning gracefully...") false;
  :return true;
}

# log and print with same text, optionally exit
:set LogPrintExit2 do={
  :local Severity [ :tostr $1 ];
  :local Name     [ :tostr $2 ];
  :local Message  [ :tostr $3 ];
  :local Exit     [ :tostr $4 ];

  :global PrintDebug;
  :global PrintDebugOverride;

  :global EitherOr;

  :local Debug [ $EitherOr ($PrintDebugOverride->$Name) $PrintDebug ];

  :local PrintSeverity do={
    :global TerminalColorOutput;

    :if ($TerminalColorOutput != true) do={
      :return $1;
    }

    :local Color { debug=96; info=97; warning=93; error=91 };
    :return ("\1B[" . $Color->$1 . "m" . $1 . "\1B[0m");
  }

  :local Log ([ $EitherOr $Name "<unknown>" ] . ": " . $Message);
  :if ($Severity ~ ("^(debug|error|info)\$")) do={
    :if ($Severity = "debug") do={ :log debug $Log; }
    :if ($Severity = "error") do={ :log error $Log; }
    :if ($Severity = "info" ) do={ :log info  $Log; }
  } else={
    :log warning $Log;
    :set Severity "warning";
  }

  :if ($Severity != "debug" || $Debug = true) do={
    :put ([ $PrintSeverity $Severity ] . ": " . $Message);
  }

  :if ($Exit = "true") do={
    :error ("Hard error to exit.");
  }
}

# log and print, once until reboot
:set LogPrintOnce do={
  :local Severity [ :tostr $1 ];
  :local Name     [ :tostr $2 ];
  :local Message  [ :tostr $3 ];

  :global LogPrintExit2;

  :global LogPrintOnceMessages;

  :if ([ :typeof $LogPrintOnceMessages ] = "nothing") do={
    :set LogPrintOnceMessages ({});
  }

  :if ($LogPrintOnceMessages->$Message = 1) do={
    :return true;
  }

  :set ($LogPrintOnceMessages->$Message) 1;
  $LogPrintExit2 $Severity $Name $Message false;
}

# create directory
:set MkDir do={
  :local Path [ :tostr $1 ];

  :global CharacterReplace;
  :global CleanFilePath;
  :global GetRandom20CharAlNum;
  :global LogPrintExit2;
  :global WaitForFile;

  :local MkTmpfs do={
    :global LogPrintExit2;
    :global WaitForFile;

    :if ([ :len [ /disk/find where slot=tmpfs type=tmpfs ] ] = 1) do={
      :return true;
    }

    $LogPrintExit2 info $0 ("Creating disk of type tmpfs.") false;
    /file/remove [ find where name="tmpfs" type="directory" ];
    :do {
      /disk/add slot=tmpfs type=tmpfs tmpfs-max-size=([ /system/resource/get total-memory ] / 3);
      $WaitForFile "tmpfs";
    } on-error={
      $LogPrintExit2 warning $0 ("Creating disk of type tmpfs failed!") false;
      :return false;
    }
    :return true;
  }

  :set Path [ $CleanFilePath $Path ];

  :if ($Path = "") do={
    :return true;
  }

  :if ([ :len [ /file/find where name=$Path type="directory" ] ] = 1) do={
    :return true;
  }

  :if ([ :pick $Path 0 5 ] = "tmpfs") do={
    :if ([ $MkTmpfs ] = false) do={
      :return false;
    }
  }

  :do {
    :local File ($Path . "/file");
    /file/add name=$File;
    $WaitForFile $File;
    /file/remove $File;
  } on-error={
    $LogPrintExit2 warning $0 ("Making directory '" . $Path . "' failed!") false;
    :return false;
  }

  :return true;
}

# prepare NotificationFunctions array
:if ([ :typeof $NotificationFunctions ] != "array") do={
  :set NotificationFunctions ({});
}

# parse the date and return a named array
:set ParseDate do={
  :local Date [ :tostr $1 ];

  :return ({ "year"=[ :tonum [ :pick $Date 0 4 ] ];
            "month"=[ :tonum [ :pick $Date 5 7 ] ];
              "day"=[ :tonum [ :pick $Date 8 10 ] ] });
}

# parse JSON into array
# Warning: This is not a complete parser!
:set ParseJson do={
  :local Input [ :tostr $1 ];

  :local InLen;
  :local Return ({});
  :local Skip 0;

  :if ([ :pick $Input 0 ] = "{") do={
    :set Input [ :pick $Input 1 ([ :len $Input ] - 1) ];
  }
  :set Input [ :toarray $Input ];
  :set InLen [ :len $Input ];

  :for I from=0 to=$InLen do={
    :if ($Skip > 0 || $Input->$I = "\n" || $Input->$I = "\r\n") do={
      :if ($Skip > 0) do={
        :set $Skip ($Skip - 1);
      }
    } else={
      :local Done false;
      :local Key ($Input->$I);
      :local Val1 ($Input->($I + 1));
      :local Val2 ($Input->($I + 2));
      :if ($Val1 = ":") do={
        :set Skip 2;
        :set ($Return->$Key) $Val2;
        :set Done true;
      }
      :if ($Done = false && $Val1 = ":[") do={
        :local Last false;
        :set Skip 1;
        :set ($Return->$Key) ({});
        :do {
          :set Skip ($Skip + 1);
          :local ValX ($Input->($I + $Skip));
          :if ([ :pick $ValX ([ :len $ValX ] - 1) ] = "]") do={
            :set Last true;
            :set ValX [ :pick $ValX 0 ([ :len $ValX ] - 1) ];
          }
          :set ($Return->$Key) (($Return->$Key), $ValX);
        } while=($Last = false && $I + $Skip < $InLen);
        :set Done true;
      }
      :if ($Done = false && $Val1 = ":[]") do={
        :set Skip 1;
        :set ($Return->$Key) ({});
        :set Done true;
      }
      :if ($Done = false) do={
        :set Skip 1;
        :set ($Return->$Key) [ :pick $Val1 1 [ :len $Val1 ] ];
      }
    }
  }

  :return $Return;
}

# parse key value store
:set ParseKeyValueStore do={
  :local Source $1;
  :if ([ :typeof $Source ] != "array") do={
    :set Source [ :tostr $1 ];
  }
  :local Result ({});
  :foreach KeyValue in=[ :toarray $Source ] do={
    :if ([ :find $KeyValue "=" ]) do={
      :set ($Result->[ :pick $KeyValue 0 [ :find $KeyValue "=" ] ]) \
        [ :pick $KeyValue ([ :find $KeyValue "=" ] + 1) [ :len $KeyValue ] ];
    } else={
      :set ($Result->$KeyValue) true;
    }
  }
  :return $Result;
}

# print lines with trailing carriage return
:set PrettyPrint do={
  :local Input [ :tostr $1 ];

  :global Unix2Dos;

  :put [ $Unix2Dos $Input ];
}

# delay a random amount of seconds
:set RandomDelay do={
  :global EitherOr;
  :global GetRandomNumber;

  :delay ([ $GetRandomNumber $1 ] . [ $EitherOr $2 "s" ]);
}

# read input from user
:set Read do={
  :return;
}

# check for required RouterOS version
:set RequiredRouterOS do={
  :local Caller   [ :tostr $1 ];
  :local Required [ :tostr $2 ];
  :local Warn     [ :tostr $3 ];

  :global IfThenElse;
  :global LogPrintExit2;
  :global VersionToNum;

  :if (!($Required ~ "^\\d+\\.\\d+((alpha|beta|rc|\\.)\\d+|)\$")) do={
    $LogPrintExit2 error $0 ("No valid RouterOS version: " . $Required) false;
    :return false;
  }

  :if ([ $VersionToNum $Required ] > [ $VersionToNum [ /system/package/update/get installed-version ] ]) do={
    :if ($Warn = "true") do={
      $LogPrintExit2 warning $0 ("This " . [ $IfThenElse ([ :pick $Caller 0 ] = ("\$")) "function" "script" ] . \
        " '" . $Caller . "' (at least specific functionality) requires RouterOS " . $Required . ". Please update!") false;
    }
    :return false;
  }
  :return true;
}

# check if script is run from terminal
:set ScriptFromTerminal do={
  :local Script [ :tostr $1 ];

  :global LogPrintExit2;

  :foreach Job in=[ /system/script/job/find where script=$Script ] do={
    :set Job [ /system/script/job/get $Job ];
    :while ([ :typeof ($Job->"parent") ] = "id") do={
      :set Job [ /system/script/job/get [ find where .id=($Job->"parent") ] ];
    }
    :if (($Job->"type") = "login") do={
      $LogPrintExit2 debug $0 ("Script " . $Script . " started from terminal.") false;
      :return true;
    }
  }
  $LogPrintExit2 debug $0 ("Script " . $Script . " NOT started from terminal.") false;

  :return false;
}

# install new scripts, update existing scripts
:set ScriptInstallUpdate do={
  :local Scripts    [ :toarray $1 ];
  :local NewComment [ :tostr   $2 ];

  :global ExpectedConfigVersion;
  :global FetchUserAgent;
  :global Identity;
  :global IDonate;
  :global NoNewsAndChangesNotification;
  :global ScriptUpdatesBaseUrl;
  :global ScriptUpdatesUrlSuffix;

  :global CertificateAvailable;
  :global EitherOr;
  :global Grep;
  :global IfThenElse;
  :global LogPrintExit2;
  :global ParseKeyValueStore;
  :global RequiredRouterOS;
  :global SendNotification2;
  :global SymbolForNotification;
  :global ValidateSyntax;

  :if ([ $CertificateAvailable "E1" ] = false) do={
    $LogPrintExit2 warning $0 ("Downloading certificate failed, trying without.") false;
  }

  :foreach Script in=$Scripts do={
    :if ([ :len [ /system/script/find where name=$Script ] ] = 0) do={
      $LogPrintExit2 info $0 ("Adding new script: " . $Script) false;
      /system/script/add name=$Script owner=$Script source="#!rsc by RouterOS\n" comment=$NewComment;
    }
  }

  :local ExpectedConfigVersionBefore $ExpectedConfigVersion;
  :local ReloadGlobalFunctions false;
  :local ReloadGlobalConfig false;

  :foreach Script in=[ /system/script/find where source~"^#!rsc by RouterOS\r?\n" ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local ScriptInfo [ $ParseKeyValueStore ($ScriptVal->"comment") ];
    :local SourceNew;

    :foreach Scheduler in=[ /system/scheduler/find where on-event~("\\b" . $ScriptVal->"name" . "\\b") ] do={
      :local SchedulerVal [ /system/scheduler/get $Scheduler ];
      :if ($ScriptVal->"policy" != $SchedulerVal->"policy") do={
        $LogPrintExit2 warning $0 ("Policies differ for script '" . $ScriptVal->"name" . \
          "' and its scheduler '" . $SchedulerVal->"name" . "'!") false;
      }
    }

    :if (!($ScriptInfo->"ignore" = true)) do={
      :do {
        :local BaseUrl [ $EitherOr ($ScriptInfo->"base-url") $ScriptUpdatesBaseUrl ];
        :local UrlSuffix [ $EitherOr ($ScriptInfo->"url-suffix") $ScriptUpdatesUrlSuffix ];
        :local Url ($BaseUrl . $ScriptVal->"name" . ".rsc" . $UrlSuffix);
        $LogPrintExit2 debug $0 ("Fetching script '" . $ScriptVal->"name" . "' from url: " . $Url) false;
        :local Result [ /tool/fetch check-certificate=yes-without-crl \
          http-header-field=({ $FetchUserAgent }) $Url output=user as-value ];
        :if ($Result->"status" = "finished") do={
          :set SourceNew ($Result->"data");
        }
      } on-error={
        :if ($ScriptVal->"source" = "#!rsc by RouterOS\n") do={
          $LogPrintExit2 warning $0 ("Failed fetching script '" . $ScriptVal->"name" . \
            "', removing dummy. Typo on installation?") false;
          /system/script/remove $Script;
        } else={
          $LogPrintExit2 warning $0 ("Failed fetching script '" . $ScriptVal->"name" . "'!") false;
        }
      }
    }

    :if ([ :len $SourceNew ] > 0) do={
      :if ($SourceNew != $ScriptVal->"source") do={
        :if ([ :pick $SourceNew 0 18 ] = "#!rsc by RouterOS\n") do={
          :local Required ([ $ParseKeyValueStore [ $Grep $SourceNew ("\23 requires RouterOS, ") ] ]->"version");
          :if ([ $RequiredRouterOS $0 [ $EitherOr $Required "0.0" ] false ] = true) do={
            :if ([ $ValidateSyntax $SourceNew ] = true) do={
              $LogPrintExit2 info $0 ("Updating script: " . $ScriptVal->"name") false;
              /system/script/set owner=($ScriptVal->"name") source=$SourceNew $Script;
              :if ($ScriptVal->"name" = "global-config") do={
                :set ReloadGlobalConfig true;
              }
              :if ($ScriptVal->"name" = "global-functions" || $ScriptVal->"name" ~ ("^mod/.")) do={
                :set ReloadGlobalFunctions true;
              }
            } else={
              $LogPrintExit2 warning $0 ("Syntax validation for script '" . $ScriptVal->"name" . \
                "' failed! Ignoring!") false;
            }
          } else={
            $LogPrintExit2 warning $0 ("The script '" . $ScriptVal->"name" . "' requires RouterOS " . \
              $Required . ", which is not met by your installation. Ignoring!") false;
          }
        } else={
          $LogPrintExit2 warning $0 ("Looks like new script '" . $ScriptVal->"name" . \
            "' is not valid (missing shebang). Ignoring!") false;
        }
      } else={
        $LogPrintExit2 debug $0 ("Script '" .  $ScriptVal->"name" . "' did not change.") false;
      }
    } else={
      $LogPrintExit2 debug $0 ("No update for script '" . $ScriptVal->"name" . "'.") false;
    }
  }

  :if ($ReloadGlobalFunctions = true) do={
    $LogPrintExit2 info $0 ("Reloading global functions.") false;
    :do {
      /system/script/run global-functions;
    } on-error={
      $LogPrintExit2 error $0 ("Reloading global functions failed!") false;
    }
  }

  :if ($ReloadGlobalConfig = true) do={
    $LogPrintExit2 info $0 ("Reloading global configuration.") false;
    :do {
      /system/script/run global-config;
    } on-error={
      $LogPrintExit2 error $0 ("Reloading global configuration failed!" . \
        " Syntax error or missing overlay?") false;
    }
  }

  :if ($ExpectedConfigVersionBefore > $ExpectedConfigVersion) do={
    $LogPrintExit2 warning $0 ("The configuration version decreased from " . \
      $ExpectedConfigVersionBefore . " to " . $ExpectedConfigVersion . \
      ". Installed an older version?") false;
  }

  :if ($ExpectedConfigVersionBefore < $ExpectedConfigVersion) do={
    :global GlobalConfigChanges;
    :global GlobalConfigMigration;
    :local ChangeLogCode;

    :do {
      :local Url ($ScriptUpdatesBaseUrl . "news-and-changes.rsc" . $ScriptUpdatesUrlSuffix);
      $LogPrintExit2 debug $0 ("Fetching news, changes and migration: " . $Url) false;
      :local Result [ /tool/fetch check-certificate=yes-without-crl \
        http-header-field=({ $FetchUserAgent }) $Url output=user as-value ];
      :if ($Result->"status" = "finished") do={
        :set ChangeLogCode ($Result->"data");
      }
    } on-error={
      $LogPrintExit2 warning $0 ("Failed fetching news, changes and migration!") false;
    }

    :if ([ :len $ChangeLogCode ] > 0) do={
      :if ([ $ValidateSyntax $ChangeLogCode ] = true) do={
        :do {
          [ :parse $ChangeLogCode ];
        } on-error={
          $LogPrintExit2 warning $0 ("The changelog failed to run!") false;
        }
      } else={
        $LogPrintExit2 warning $0 ("The changelog failed syntax validation!") false;
      }
    }

    :if ([ :len $GlobalConfigMigration ] > 0) do={
      :for I from=($ExpectedConfigVersionBefore + 1) to=$ExpectedConfigVersion do={
        :local Migration ($GlobalConfigMigration->[ :tostr $I ]);
        :if ([ :typeof $Migration ] = "str") do={
          :if ([ $ValidateSyntax $Migration ] = true) do={
            $LogPrintExit2 info $0 ("Applying migration for change " . $I . ": " . $Migration) false;
            :do {
              [ :parse $Migration ];
            } on-error={
              $LogPrintExit2 warning $0 ("Migration code for change " . $I . " failed to run!") false;
            }
          } else={
            $LogPrintExit2 warning $0 ("Migration code for change " . $I . " failed syntax validation!") false;
          }
        }
      }
    }

    :local NotificationMessage ("The configuration version on " . $Identity . " increased " . \
       "to " . $ExpectedConfigVersion . ", current configuration may need modification. " . \
       "Please review and update global-config-overlay, then re-run global-config.");
    $LogPrintExit2 info $0 ($NotificationMessage) false;

    :if ([ :len $GlobalConfigChanges ] > 0) do={
      :set NotificationMessage ($NotificationMessage . "\n\nChanges:");
      :for I from=($ExpectedConfigVersionBefore + 1) to=$ExpectedConfigVersion do={
        :local Change ($GlobalConfigChanges->[ :tostr $I ]);
        :set NotificationMessage ($NotificationMessage . "\n " . \
            [ $SymbolForNotification "pushpin" "* " ] . $Change);
        $LogPrintExit2 info $0 ("Change " . $I . ": " . $Change) false;
      }
    } else={
      :set NotificationMessage ($NotificationMessage . "\n\nNews and changes are not available.");
    }

    :if ($NoNewsAndChangesNotification != true) do={
      :local Link;
      :if ($IDonate != true) do={
        :set NotificationMessage ($NotificationMessage . \
          "\n\n==== donation hint ====\n" . \
          "This project is developed in private spare time and usage is " . \
          "free of charge for you. If you like the scripts and think this is " . \
          "of value for you or your business please consider a donation.");
        :set Link "https://git.eworm.de/cgit/routeros-scripts/about/#donate";
      }

      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification "pushpin" ] . "News and configuration changes"); \
        message=$NotificationMessage; link=$Link });
    }

    :set GlobalConfigChanges;
    :set GlobalConfigMigration;
  }
}

# lock script against multiple invocation
:set ScriptLock do={
  :local Script   [ :tostr $1 ];
  :local DoReturn $2;
  :local WaitMax  ([ :tonum $3 ] * 10);

  :global GetRandom20CharAlNum;
  :global IfThenElse;
  :global LogPrintExit2;

  :global ScriptLockOrder;
  :if ([ :typeof $ScriptLockOrder ] = "nothing") do={
    :set ScriptLockOrder ({});
  }
  :if ([ :typeof ($ScriptLockOrder->$Script) ] = "nothing") do={
    :set ($ScriptLockOrder->$Script) ({});
  }

  :local JobCount do={
    :local Script [ :tostr $1 ];

    :return [ :len [ /system/script/job/find where script=$Script ] ];
  }

  :local TicketCount do={
    :local Script [ :tostr $1 ];

    :global ScriptLockOrder;

    :local Count 0;
    :foreach Ticket in=($ScriptLockOrder->$Script) do={
      :if ([ :typeof $Ticket ] != "nothing") do={
        :set Count ($Count + 1);
      }
    }
    :return $Count;
  }

  :local IsFirstTicket do={
    :local Script [ :tostr $1 ];
    :local Check  [ :tostr $2 ];

    :global ScriptLockOrder;

    :foreach Ticket in=($ScriptLockOrder->$Script) do={
      :if ($Ticket = $Check) do={ :return true; }
      :if ([ :typeof $Ticket ] != "nothing" && $Ticket != $Check) do={ :return false; }
    }
    :return false;
  }

  :local AddTicket do={
    :local Script [ :tostr $1 ];
    :local Add    [ :tostr $2 ];

    :global ScriptLockOrder;

    :while (true) do={
      :local Pos [ :len ($ScriptLockOrder->$Script) ];
      :set ($ScriptLockOrder->$Script->$Pos) $Add;
      :delay 10ms;
      :if (($ScriptLockOrder->$Script->$Pos) = $Add) do={ :return true; }
    }
  }

  :local RemoveTicket do={
    :local Script [ :tostr $1 ];
    :local Remove [ :tostr $2 ];

    :global ScriptLockOrder;

    :foreach Id,Ticket in=($ScriptLockOrder->$Script) do={
      :while (($ScriptLockOrder->$Script->$Id) = $Remove) do={
        :set ($ScriptLockOrder->$Script->$Id);
        :delay 10ms;
      }
    }
  }

  :local CleanupTickets do={
    :local Script [ :tostr $1 ];

    :global ScriptLockOrder;

    :foreach Ticket in=($ScriptLockOrder->$Script) do={
      :if ([ :typeof $Ticket ] != "nothing") do={
        :return false;
      }
    }

    :set ($ScriptLockOrder->$Script) ({});
  }

  :if ([ :len [ /system/script/find where name=$Script ] ] = 0) do={
    $LogPrintExit2 error $0 ("A script named '" . $Script . "' does not exist!") true;
  }

  :if ([ $JobCount $Script ] = 0) do={
    $LogPrintExit2 error $0 ("No script '" . $Script . "' is running!") true;
  }

  :if ([ $TicketCount $Script ] >= [ $JobCount $Script ]) do={
    $LogPrintExit2 error $0 ("More tickets than running scripts '" . $Script . "', resetting!") false;
    :set ($ScriptLockOrder->$Script) ({});
    /system/script/job/remove [ find where script=$Script ];
  }

  :local MyTicket [ $GetRandom20CharAlNum 6 ];
  $AddTicket $Script $MyTicket;

  :local WaitCount 0;
  :while ($WaitMax > $WaitCount && ([ $IsFirstTicket $Script $MyTicket ] = false || [ $TicketCount $Script ] < [ $JobCount $Script ])) do={
    :set WaitCount ($WaitCount + 1);
    :delay 100ms;
  }

  :if ([ $IsFirstTicket $Script $MyTicket ] = true && [ $TicketCount $Script ] = [ $JobCount $Script ]) do={
    $RemoveTicket $Script $MyTicket;
    $CleanupTickets $Script;
    :return false;
  }

  $RemoveTicket $Script $MyTicket;
  $LogPrintExit2 info $0 ("Script '" . $Script . "' started more than once" . [ $IfThenElse ($WaitCount > 0) \
    " and timed out waiting for lock" "" ] . "... Aborting.") [ $IfThenElse ($DoReturn = true) false true ];
  :return true;
}

# send notification via NotificationFunctions - expects at least two string arguments
:set SendNotification do={
  :global SendNotification2;

  $SendNotification2 ({ subject=$1; message=$2; link=$3; silent=$4 });
}

# send notification via NotificationFunctions - expects one array argument
:set SendNotification2 do={
  :local Notification $1;

  :global NotificationFunctions;

  :foreach FunctionName,Discard in=$NotificationFunctions do={
    ($NotificationFunctions->$FunctionName) \
      ("\$NotificationFunctions->\"" . $FunctionName . "\"") \
      $Notification;
  }
}

# return UTF-8 symbol for unicode name
:set SymbolByUnicodeName do={
  :local Symbols {
    "abacus"="\F0\9F\A7\AE";
    "alarm-clock"="\E2\8F\B0";
    "calendar"="\F0\9F\93\85";
    "card-file-box"="\F0\9F\97\83";
    "chart-decreasing"="\F0\9F\93\89";
    "chart-increasing"="\F0\9F\93\88";
    "cloud"="\E2\98\81";
    "cross-mark"="\E2\9D\8C";
    "earth"="\F0\9F\8C\8D";
    "fire"="\F0\9F\94\A5";
    "floppy-disk"="\F0\9F\92\BE";
    "high-voltage-sign"="\E2\9A\A1";
    "incoming-envelope"="\F0\9F\93\A8";
    "information"="\E2\84\B9";
    "large-orange-circle"="\F0\9F\9F\A0";
    "large-red-circle"="\F0\9F\94\B4";
    "link"="\F0\9F\94\97";
    "lock-with-ink-pen"="\F0\9F\94\8F";
    "memo"="\F0\9F\93\9D";
    "mobile-phone"="\F0\9F\93\B1";
    "pushpin"="\F0\9F\93\8C";
    "scissors"="\E2\9C\82";
    "sparkles"="\E2\9C\A8";
    "speech-balloon"="\F0\9F\92\AC";
    "up-arrow"="\E2\AC\86";
    "warning-sign"="\E2\9A\A0";
    "white-heavy-check-mark"="\E2\9C\85"
  }

  :return (($Symbols->$1) . "\EF\B8\8F");
}

# return symbol for notification
:set SymbolForNotification do={
  :global NotificationsWithSymbols;
  :global SymbolByUnicodeName;

  :if ($NotificationsWithSymbols != true) do={
    :return [ :tostr $2 ];
  }
  :local Return "";
  :foreach Symbol in=[ :toarray $1 ] do={
    :set Return ($Return . [ $SymbolByUnicodeName $Symbol ]);
  }
  :return ($Return . " ");
}

# convert line endings, UNIX -> DOS
:set Unix2Dos do={
  :local Input [ :tostr $1 ];

  :global CharacterReplace;

  :return [ $CharacterReplace [ $CharacterReplace $Input \
    ("\n") ("\r\n") ] ("\r\r\n") ("\r\n") ];
}

# url encoding
:set UrlEncode do={
  :local Input [ :tostr $1 ];

  :if ([ :len $Input ] = 0) do={
    :return "";
  }

  :local Return "";
  :local Chars ("\n\r !\"#\$%&'()*+,:;<=>?@[\\]^`{|}~");
  :local Subs { "%0A"; "%0D"; "%20"; "%21"; "%22"; "%23"; "%24"; "%25"; "%26"; "%27";
         "%28"; "%29"; "%2A"; "%2B"; "%2C"; "%3A"; "%3B"; "%3C"; "%3D"; "%3E"; "%3F";
         "%40"; "%5B"; "%5C"; "%5D"; "%5E"; "%60"; "%7B"; "%7C"; "%7D"; "%7E" };

  :for I from=0 to=([ :len $Input ] - 1) do={
    :local Char [ :pick $Input $I ];
    :local Replace [ :find $Chars $Char ];

    :if ([ :typeof $Replace ] = "num") do={
      :set Char ($Subs->$Replace);
    }
    :set Return ($Return . $Char);
  }

  :return $Return;
}

# basic syntax validation
:set ValidateSyntax do={
  :local Code [ :tostr $1 ];

  :do {
    [ :parse (":local Validate do={\n" . $Code . "\n}") ];
  } on-error={
    :return false;
  }
  :return true;
}

# convert version string to numeric value
:set VersionToNum do={
  :local Input [ :tostr $1 ];
  :local Multi 0x1000000;
  :local Return 0;

  :global CharacterReplace;

  :set Input [ $CharacterReplace $Input "." "," ];
  :foreach I in={ "alpha"; "beta"; "rc" } do={
    :set Input [ $CharacterReplace $Input $I ("," . $I . ",") ];
  }

  :foreach Value in=([ :toarray $Input ], 0) do={
    :local Num [ :tonum $Value ];
    :if ($Multi = 0x100) do={
      :if ([ :typeof $Num ] = "num") do={
        :set Return ($Return + 0xff00);
        :set Multi ($Multi / 0x100);
      } else={
        :if ($Value = "alpha") do={ :set Return ($Return + 0x3f00); }
        :if ($Value = "beta") do={ :set Return ($Return + 0x5f00); }
        :if ($Value = "rc") do={ :set Return ($Return + 0x7f00); }
      }
    }
    :if ([ :typeof $Num ] = "num") do={ :set Return ($Return + ($Value * $Multi)); }
    :set Multi ($Multi / 0x100);
  }

  :return $Return;
}

# wait for default route to be reachable
:set WaitDefaultRouteReachable do={
  :global IsDefaultRouteReachable;

  :while ([ $IsDefaultRouteReachable ] = false) do={
    :delay 1s;
  }
}

# wait for DNS to resolve
:set WaitDNSResolving do={
  :global IsDNSResolving;

  :while ([ $IsDNSResolving ] = false) do={
    :delay 1s;
  }
}

# wait for file to be available
:set WaitForFile do={
  :local FileName [ :tostr  $1 ];
  :local WaitTime [ :totime $2 ];

  :global CleanFilePath;
  :global EitherOr;

  :set FileName [ $CleanFilePath $FileName ];
  :local I 1;
  :local Delay ([ :totime [ $EitherOr $WaitTime 2s ] ] / 20);

  :while ([ :len [ /file/find where name=$FileName ] ] = 0) do={
    :if ($I >= 20) do={
      :return false;
    }
    :delay $Delay;
    :set I ($I + 1);
  }
  :return true;
}

# wait to be fully connected (default route is reachable, time is sync, DNS resolves)
:set WaitFullyConnected do={
  :global WaitDefaultRouteReachable;
  :global WaitDNSResolving;
  :global WaitTimeSync;

  $WaitDefaultRouteReachable;
  $WaitTimeSync;
  $WaitDNSResolving;
}

# wait for time to become synced
:set WaitTimeSync do={
  :global IsTimeSync;

  :while ([ $IsTimeSync ] = false) do={
    :delay 1s;
  }
}

# load modules
:foreach Script in=[ /system/script/find where name ~ "^mod/." ] do={
  :local ScriptVal [ /system/script/get $Script ];
  :if ([ $ValidateSyntax ($ScriptVal->"source") ] = true) do={
    :do {
      /system/script/run $Script;
    } on-error={
      $LogPrintExit2 error $0 ("Module '" . $ScriptVal->"name" . "' failed to run.") false;
    }
  } else={
    $LogPrintExit2 error $0 ("Module '" . $ScriptVal->"name" . "' failed syntax validation, skipping.") false;
  }
}

# signal we are ready
:set GlobalFunctionsReady true;
