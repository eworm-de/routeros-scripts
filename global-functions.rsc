#!rsc by RouterOS
# RouterOS script: global-functions
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.19
# requires device-mode, fetch, scheduler
#
# global functions
# https://rsc.eworm.de/

:local ScriptName [ :jobname ];

# Git commit id & info, expected configuration version
:global CommitId "unknown";
:global CommitInfo "unknown";
:global ExpectedConfigVersion 138;

# global variables not to be changed by user
:global GlobalFunctionsReady false;
:global Identity [ /system/identity/get name ];

# global functions
:global AlignRight;
:global CertificateAvailable;
:global CertificateDownload;
:global CertificateNameByCN;
:global CharacterMultiply;
:global CharacterReplace;
:global CleanFilePath;
:global CleanName;
:global DeviceInfo;
:global Dos2Unix;
:global DownloadPackage;
:global EitherOr;
:global EscapeForRegEx;
:global ExitError;
:global FetchHuge;
:global FetchUserAgentStr;
:global FileExists;
:global FileGet;
:global FormatLine;
:global FormatMultiLines;
:global GetMacVendor;
:global GetRandom20CharAlNum;
:global GetRandom20CharHex;
:global GetRandomNumber;
:global Grep;
:global HexToNum;
:global HumanReadableNum;
:global IfThenElse;
:global IsDefaultRouteReachable;
:global IsDNSResolving;
:global IsFullyConnected;
:global IsMacLocallyAdministered;
:global IsTimeSync;
:global LogPrint;
:global LogPrintOnce;
:global LogPrintVerbose;
:global MAX;
:global MIN;
:global MkDir;
:global NotificationFunctions;
:global ParseDate;
:global ParseKeyValueStore;
:global PrettyPrint;
:global ProtocolStrip;
:global RandomDelay;
:global RequiredRouterOS;
:global RmDir;
:global RmFile;
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

# align string to the right
:set AlignRight do={
  :local Input [ :tostr $1 ];
  :local Len   [ :tonum $2 ];

  :global CharacterMultiply;
  :global EitherOr;

  :set Len [ $EitherOr $Len 8 ];
  :local Spaces [ $CharacterMultiply " " $Len ];

  :return ([ :pick $Spaces 0 ($Len - [ :len $Input ]) ] . $Input);
}

# check and download required certificate
:set CertificateAvailable do={
  :local CommonName [ :tostr $1 ];

  :global CertificateDownload;
  :global LogPrint;
  :global ParseKeyValueStore;

  :if ([ /system/resource/get free-hdd-space ] < 8388608 && \
       [ /certificate/settings/get crl-download ] = true && \
       [ /certificate/settings/get crl-store ] = "system") do={
    $LogPrint warning $0 ("This system has low free flash space but " . \
      "is configured to download certificate CRLs to system!");
  }

  :if ([ :len $CommonName ] = 0) do={
    $LogPrint warning $0 ("No CommonName given!");
    :return false;
  }

  :if ([ /certificate/settings/get builtin-trust-anchors ] = "trusted" && \
       [ :len [ /certificate/builtin/find where common-name=$CommonName ] ] > 0) do={
    :return true;
  }

  :if ([ :len [ /certificate/find where common-name=$CommonName ] ] = 0) do={
    $LogPrint info $0 ("Certificate with CommonName '" . $CommonName . "' not available.");
    :if ([ $CertificateDownload $CommonName ] = false) do={
      :return false;
    }
  }

  :if ([ :len [ /certificate/find where common-name=$CommonName ] ] > 1) do={
    $LogPrint info $0 ("There are " . $CertCount . " Certificates with CommonName '" . $CommonName . "'. Should be ok.");
    :return true;
  }

  :local CertVal [ /certificate/get [ find where common-name=$CommonName ] ];
  :while (($CertVal->"akid") != "" && ($CertVal->"akid") != ($CertVal->"skid")) do={
    :if ([ :len [ /certificate/find where skid=($CertVal->"akid") ] ] = 0) do={
      $LogPrint info $0 ("Certificate chain for '" . $CommonName . \
        "' is incomplete, missing '" . ([ $ParseKeyValueStore ($CertVal->"issuer") ]->"CN") . "'.");
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

  :global ScriptUpdatesBaseUrl;
  :global ScriptUpdatesUrlSuffix;

  :global CertificateAvailable;
  :global CertificateNameByCN;
  :global CleanName;
  :global FetchUserAgentStr;
  :global LogPrint;
  :global RmFile;
  :global WaitForFile;

  $LogPrint info $0 ("Downloading and importing certificate with " . \
      "CommonName '" . $CommonName . "'.");
  :local FileName ([ $CleanName $CommonName ] . ".pem");
  :do {
    /tool/fetch check-certificate=yes-without-crl http-header-field=({ [ $FetchUserAgentStr $0 ] }) \
      ($ScriptUpdatesBaseUrl . "certs/" . $FileName . $ScriptUpdatesUrlSuffix) \
      dst-path=$FileName as-value;
    $WaitForFile $FileName;
  } on-error={
    $LogPrint warning $0 ("Failed downloading certificate with CommonName '" . $CommonName . \
      "' from repository! Trying fallback to mkcert.org...");
    :do {
      :if ([ :len [ /certificate/find where common-name="ISRG Root X1" ] ] = 0) do={
        $LogPrint error $0 ("Required certificate is not available.");
        :return false;
      }
      /tool/fetch check-certificate=yes-without-crl http-header-field=({ [ $FetchUserAgentStr $0 ] }) \
        "https://mkcert.org/generate/" http-data=[ :serialize to=json ({ $CommonName }) ] \
        dst-path=$FileName as-value;
      $WaitForFile $FileName;
      :if ([ /file/get $FileName size ] = 0) do={
        $RmFile $FileName;
        :error false;
      }
    } on-error={
      $LogPrint warning $0 ("Failed downloading certificate with CommonName '" . $CommonName . "'!");
      :return false;
    }
  }

  /certificate/import file-name=$FileName passphrase="" as-value;
  :delay 1s;
  $RmFile $FileName;

  :if ([ :len [ /certificate/find where common-name=$CommonName ] ] = 0) do={
    /certificate/remove [ find where name~("^" . $FileName . "_[0-9]+\$") ];
    $LogPrint warning $0 ("Certificate with CommonName '" . $CommonName . "' still unavailable!");
    :return false;
  }

  :foreach Cert in=[ /certificate/find where name~("^" . $FileName . "_[0-9]+\$") ] do={
    $CertificateNameByCN [ /certificate/get $Cert common-name ];
  }
  :return true;
}

# name a certificate by its common-name
:set CertificateNameByCN do={
  :local Match [ :tostr $1 ];

  :global CleanName;
  :global LogPrint;

  :local Cert ([ /certificate/find where (common-name=$Match or fingerprint=$Match or name=$Match) ]->0);
  :if ([ :len $Cert ] = 0) do={
    $LogPrint warning $0 ("No matching certificate found.");
    :return false;
  }
  :local CommonName [ /certificate/get $Cert common-name ];
  /certificate/set $Cert name=[ $CleanName $CommonName ];
  :return true;
}

# multiply given character(s)
:set CharacterMultiply do={
  :local Return "";
  :for I from=1 to=$2 do={
    :set Return ($Return . $1);
  }
  :return $Return;
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

# clean name for DNS, file and more
:set CleanName do={
  :local Input [ :tostr $1 ];

  :local Return "";

  :for I from=0 to=([ :len $Input ] - 1) do={
    :local Char [ :pick $Input $I ];
    :if ([ :typeof [ find "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" $Char ] ] = "nil") do={
      :do {
        :if ([ :len $Return ] = 0) do={
          :error true;
        }
        :if ([ :pick $Return ([ :len $Return ] - 1) ] = "-") do={
          :error true;
        }
        :set Char "-";
      } on-error={
        :set Char "";
      }
    }
    :set Return ($Return . $Char);
  }
  :return $Return;
}

# get readable device info
:set DeviceInfo do={
  :global CommitId;
  :global CommitInfo;
  :global ExpectedConfigVersion;
  :global Identity;

  :global IfThenElse;
  :global FormatLine;

  :local License [ /system/license/get ];
  :local Resource [ /system/resource/get ];
  :local RouterBoard;
  :do {
    :set RouterBoard [[ :parse "/system/routerboard/get" ]];
  } on-error={ }
  :local Snmp [ /snmp/get ];
  :local Update [ /system/package/update/get ];

  :return ( \
    [ $FormatLine "Hostname" $Identity ] . "\n" . \
    [ $IfThenElse ([ :len ($Snmp->"location") ] > 0) \
      ([ $FormatLine "Location" ($Snmp->"location") ] . "\n") ] . \
    [ $IfThenElse ([ :len ($Snmp->"contact") ] > 0) \
      ([ $FormatLine "Contact" ($Snmp->"contact") ] . "\n") ] . \
    "Hardware:\n" . \
    [ $FormatLine "    Board" ($Resource->"board-name") ] . "\n" . \
    [ $FormatLine "    Arch" ($Resource->"architecture-name") ] . "\n" . \
    [ $IfThenElse ($RouterBoard->"routerboard" = true) \
      ([ $FormatLine "    Model" ($RouterBoard->"model") ] . \
       [ $IfThenElse ([ :len ($RouterBoard->"revision") ] > 0) \
           (" " . $RouterBoard->"revision") ] . "\n" . \
       [ $FormatLine "    Serial" ($RouterBoard->"serial-number") ] . "\n") ] . \
    [ $IfThenElse ([ :len ($License->"nlevel") ] > 0) \
      ([ $FormatLine "    License" ("level " . ($License->"nlevel")) ] . "\n") ] . \
    "RouterOS:\n" . \
    [ $IfThenElse ([ :len ($License->"level") ] > 0) \
      ([ $FormatLine "    License" ("level " . ($License->"level")) ] . "\n") ] . \
    [ $FormatLine "    Channel" ($Update->"channel") ] . "\n" . \
    [ $FormatLine "    Installed" ($Update->"installed-version") ] . "\n" . \
    [ $IfThenElse ([ :typeof ($Update->"latest-version") ] != "nothing" && \
        $Update->"installed-version" != $Update->"latest-version") \
      ([ $FormatLine "    Available" ($Update->"latest-version") ] . "\n") ] . \
    [ $IfThenElse ($RouterBoard->"routerboard" = true && \
        $RouterBoard->"current-firmware" != $RouterBoard->"upgrade-firmware") \
      ([ $FormatLine "    Firmware" ($RouterBoard->"current-firmware") ] . "\n") ] . \
    "RouterOS-Scripts:\n" . \
    [ $IfThenElse ($CommitId != "unknown") \
      ([ $FormatLine "    Commit" ($CommitInfo . "/" . [ :pick $CommitId 0 8 ]) ] . "\n") ] . \
    [ $FormatLine "    Version" $ExpectedConfigVersion ]);
}

# convert line endings, DOS -> UNIX
:set Dos2Unix do={
  :return [ :tolf [ :tostr $1 ] ];
}

# download package from upgrade server
:set DownloadPackage do={
  :local PkgName [ :tostr $1 ];
  :local PkgVer  [ :tostr $2 ];
  :local PkgArch [ :tostr $3 ];
  :local PkgDir  [ :tostr $4 ];

  :global CertificateAvailable;
  :global CleanFilePath;
  :global FileExists;
  :global LogPrint;
  :global MkDir;
  :global RmFile;
  :global WaitForFile;

  :if ([ :len $PkgName ] = 0) do={ :return false; }
  :if ([ :len $PkgVer  ] = 0) do={ :set PkgVer  [ /system/package/update/get installed-version ]; }
  :if ([ :len $PkgArch ] = 0) do={ :set PkgArch [ /system/resource/get architecture-name ]; }

  :if ($PkgName = "system") do={ :set PkgName "routeros"; }

  :local PkgFile ($PkgName . "-" . $PkgVer . "-" . $PkgArch . ".npk");
  :if ($PkgArch = "x86_64") do={ :set PkgFile ($PkgName . "-" . $PkgVer . ".npk"); }
  :local PkgDest [ $CleanFilePath ($PkgDir . "/" . $PkgFile) ];

  :if ([ $MkDir $PkgDir ] = false) do={
    $LogPrint warning $0 ("Failed creating directory, not downloading package.");
    :return false;
  }

  :if ([ $FileExists $PkgDest "package" ] = true) do={
    $LogPrint info $0 ("Package file " . $PkgName . " already exists.");
    :return true;
  }

  :if ([ $CertificateAvailable "ISRG Root X1" ] = false) do={
    $LogPrint error $0 ("Downloading required certificate failed.");
    :return false;
  }

  :local Url ("https://upgrade.mikrotik.com/routeros/" . $PkgVer . "/" . $PkgFile);
  $LogPrint info $0 ("Downloading package file '" . $PkgName . "'...");
  $LogPrint debug $0 ("... from url: " . $Url);

  :onerror Err {
    /tool/fetch check-certificate=yes-without-crl $Url dst-path=$PkgDest;
    $WaitForFile $PkgDest;
  } do={
    $LogPrint warning $0 ("Downloading package file '" . $PkgName . "' failed: " . $Err);
    :return false;
  }

  :if ([ $FileExists $PkgDest "package" ] = false) do={
    $LogPrint warning $0 ("Downloaded file is not a package, removing.");
    $RmFile $PkgDest;
    :return false;
  }

  :return true;
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
  # this works for boolean values, literal ones with parentheses
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

# simple macro to print error message on unintentional error
:set ExitError do={
  :local ExitOK [ :tostr $1 ];
  :local Name   [ :tostr $2 ];
  :local Error  [ :tostr $3 ];

  :global IfThenElse;
  :global LogPrint; 

  :if ($ExitOK = "false") do={
    $LogPrint error $Name ([ $IfThenElse ([ :pick $Name 0 1 ] = "\$") \
        "Function" "Script" ] . " '" . $Name . "' exited with error" . \
        [ $IfThenElse (!($Error ~ "^(|true|false)\$")) (": " . $Error) "." ]);
  }
}

# fetch huge data to file, read in chunks
:set FetchHuge do={
  :local ScriptName [ :tostr $1 ];
  :local Url        [ :tostr $2 ];
  :local CheckCert  [ :tostr $3 ];

  :global CleanName;
  :global FetchUserAgentStr;
  :global GetRandom20CharAlNum;
  :global IfThenElse;
  :global LogPrint;
  :global MkDir;
  :global RmDir;
  :global RmFile;
  :global WaitForFile;

  :set CheckCert [ $IfThenElse ($CheckCert = "false") "no" "yes-without-crl" ];

  :local DirName ("tmpfs/" . [ $CleanName $ScriptName ]);
  :if ([ $MkDir $DirName ] = false) do={
    $LogPrint error $0 ("Failed creating directory!");
    :return false;
  }

  :local FileName ($DirName . "/" . [ $CleanName $0 ] . "-" . [ $GetRandom20CharAlNum ]);
  :onerror Err {
    /tool/fetch check-certificate=$CheckCert $Url dst-path=$FileName \
      http-header-field=({ [ $FetchUserAgentStr $ScriptName ] }) as-value;
  } do={
    :if ([ $WaitForFile $FileName 500ms ] = true) do={
      $RmFile $FileName;
    }
    $LogPrint debug $0 ("Failed downloading from " . $Url . " - " . $Err);
    $RmDir $DirName;
    :return false;
  }
  $WaitForFile $FileName;

  :local FileSize [ /file/get $FileName size ];
  :local Return "";
  :local VarSize 0;
  :while ($VarSize != $FileSize) do={
    :set Return ($Return . ([ /file/read offset=$VarSize chunk-size=32768 file=$FileName as-value ]->"data"));
    :set FileSize [ /file/get $FileName size ];
    :set VarSize [ :len $Return ];
    :if ($VarSize > $FileSize) do={
      :delay 100ms;
    }
  }
  $RmDir $DirName;
  :return $Return;
}

# generate user agent string for fetch
:set FetchUserAgentStr do={
  :local Caller [ :tostr $1 ];

  :local Resource [ /system/resource/get ];

  :return ("User-Agent: Mikrotik/" . $Resource->"version" . " " . \
    $Resource->"architecture-name" . " " . $Caller . "/Fetch (https://rsc.eworm.de/)");
}

# check for existence of file, optionally with type
:set FileExists do={
  :local FileName [ :tostr $1 ];
  :local Type     [ :tostr $2 ];

  :global FileGet;

  :local FileVal [ $FileGet $FileName ];
  :if ($FileVal = false) do={
    :return false;
  }

  :if ([ :len ($FileVal->"size") ] = 0) do={
    :return false;
  }

  :if ([ :len $Type ] = 0 || $FileVal->"type" = $Type) do={
    :return true;
  }

  :return false;
}

# get file properties in array, or false on error
:set FileGet do={
  :local FileName [ :tostr $1 ];

  :global WaitForFile;

  :if ([ $WaitForFile $FileName 0s ] = false) do={
    :return false;
  }

  :local FileVal false;
  :do {
    :set FileVal [ /file/get $FileName ];
  } on-error={ }

  :return $FileVal;
}

# format a line for output
:set FormatLine do={
  :local Key    [ :tostr $1 ];
  :local Value  [ :tostr $2 ];
  :local Indent [ :tonum $3 ];
  :local Spaces;
  :local Return "";

  :global CharacterMultiply;
  :global EitherOr;

  :set Indent [ $EitherOr $Indent 16 ];
  :local Spaces [ $CharacterMultiply " " $Indent ];

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
  :global LogPrint;

  :if ([ $IsMacLocallyAdministered $Mac ] = true) do={
    :return "locally administered";
  }

  :do {
    :if ([ $CertificateAvailable "GTS Root R4" ] = false) do={
      $LogPrint warning $0 ("Downloading required certificate failed.");
      :error false;
    }
    :local Vendor ([ /tool/fetch check-certificate=yes-without-crl \
        ("https://api.macvendors.com/" . [ :pick $Mac 0 8 ]) output=user as-value ]->"data");
    :return $Vendor;
  } on-error={
    :onerror Err {
      /tool/fetch check-certificate=yes-without-crl ("https://api.macvendors.com/") \
        output=none as-value;
      $LogPrint debug $0 ("The mac vendor is not known in database.");
    } do={
      $LogPrint warning $0 ("Failed getting mac vendor: " . $Err);
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

  :global HexToNum;

  :if ([ :pick $Input 0 ] = "*") do={
    :return [ $HexToNum [ :pick  $Input 1 [ :len $Input ] ] ];
  }

  :return [ :tonum ("0x" . $Input) ];
}

# return human readable number
:set HumanReadableNum do={
  :local Input [ :tonum $1 ];
  :local Base  [ :tonum $2 ];

  :global EitherOr;
  :global IfThenElse;

  :local Prefix "kMGTPE";
  :local Pow 1;

  :set Base [ $EitherOr $Base 1024 ];
  :local Bin [ $IfThenElse ($Base = 1024) "i" "" ];

  :if ($Input < $Base) do={
    :return $Input;
  }

  :for I from=0 to=[ :len $Prefix ] do={
    :set Pow ($Pow * $Base);
    :if ($Input / $Base < $Pow) do={
      :set Prefix [ :pick $Prefix $I ];
      :local Tmp1 ($Input * 100 / $Pow);
      :local Tmp2 ($Tmp1 / 100);
      :if ($Tmp2 >= 100) do={
        :return ($Tmp2 . $Prefix . $Bin);
      }
      :return ($Tmp2 . "." . \
          [ :pick $Tmp1 [ :len $Tmp2 ] ([ :len $Tmp1 ] - [ :len $Tmp2 ] + 1) ] . \
          $Prefix . $Bin);
    }
  }
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

  :global LogPrintOnce;

  :if ($IsTimeSyncCached = true) do={
    :return true;
  }

  :if ([ /system/ntp/client/get enabled ] = true) do={
    :if ([ /system/ntp/client/get status ] = "synchronized") do={
      :set IsTimeSyncCached true;
      :return true;
    }

    :local Uptime [ /system/resource/get uptime ];
    :if ([ :typeof $IsTimeSyncResetNtp ] = "nothing") do={
      :set IsTimeSyncResetNtp $Uptime;
    }
    :if ($Uptime - $IsTimeSyncResetNtp < 3m) do={
      :return false;
    }

    $LogPrintOnce warning $0 ("The ntp client is configured, but did not sync.");
    :set IsTimeSyncResetNtp $Uptime;
    /system/ntp/client/set enabled=no;
    :delay 20ms;
    /system/ntp/client/set enabled=yes;
    :return false;
  }

  :if ([ /system/license/get ]->"level" = "free" || \
       [ /system/resource/get ]->"board-name" = "x86") do={
    $LogPrintOnce debug $0 ("No ntp client configured, relying on RTC for CHR free license and x86.");
    :return true;
  }

  :if ([ /ip/cloud/get update-time ] = true) do={
    :if ([ :typeof [ /ip/cloud/get public-address ] ] = "ip") do={
      :set IsTimeSyncCached true;
      :return true;
    }
    :return false;
  }

  $LogPrintOnce debug $0 ("No time source configured! Returning gracefully...");
  :return true;
}

# log and print with same text
:set LogPrint do={
  :local Severity [ :tostr $1 ];
  :local Name     [ :tostr $2 ];
  :local Message  [ :tostr $3 ];

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
}

# log and print, once until reboot
:set LogPrintOnce do={
  :local Severity [ :tostr $1 ];
  :local Name     [ :tostr $2 ];
  :local Message  [ :tostr $3 ];

  :global LogPrint;

  :global LogPrintOnceMessages;

  :if ([ :typeof $LogPrintOnceMessages ] = "nothing") do={
    :set LogPrintOnceMessages ({});
  }

  :if ($LogPrintOnceMessages->$Message = 1) do={
    :return false;
  }

  :if ([ :len [ /log/find where message=($Name . ": " . $Message) ] ] > 0) do={
    $LogPrint warning $0 \
      ("The message is already in log, scripting subsystem may have crashed before!");
  }

  :set ($LogPrintOnceMessages->$Message) 1;
  $LogPrint $Severity $Name $Message;
  :return true;
}

# The function $LogPrintVerbose is declared, but has no code, intentionally.
# https://rsc.eworm.de/DEBUG.md#verbose-output

# get max value
:set MAX do={
  :if ($1 > $2) do={ :return $1; }
  :return $2;
}

# get min value
:set MIN do={
  :if ($1 < $2) do={ :return $1; }
  :return $2;
}

# create directory
:set MkDir do={
  :local Path [ :tostr $1 ];

  :global CleanFilePath;
  :global FileGet;
  :global LogPrint;
  :global RmDir;
  :global WaitForFile;

  :local MkTmpfs do={
    :global LogPrint;
    :global WaitForFile;

    :local TmpFs [ /disk/find where slot=tmpfs type=tmpfs ];
    :if ([ :len $TmpFs ] = 1) do={
      :if ([ /disk/get $TmpFs disabled ] = true) do={
        $LogPrint info $0 ("The tmpfs is disabled, enabling.");
        /disk/enable $TmpFs;
      }
      :return true;
    }

    $LogPrint info $0 ("Creating disk of type tmpfs.");
    $RmDir "tmpfs";
    :onerror Err {
      /disk/add slot=tmpfs type=tmpfs tmpfs-max-size=([ /system/resource/get total-memory ] / 3);
      $WaitForFile "tmpfs";
    } do={
      $LogPrint warning $0 ("Creating disk of type tmpfs failed: " . $Err);
      :return false;
    }
    :return true;
  }

  :set Path [ $CleanFilePath $Path ];

  :if ($Path = "") do={
    :return true;
  }

  $LogPrint debug $0 ("Making directory: " . $Path);

  :local PathVal [ $FileGet $Path ];
  :if ($PathVal->"type" = "directory") do={
    $LogPrint debug $0 ("... which already exists.");
    :return true;
  }

  :if ([ :pick $Path 0 5 ] = "tmpfs") do={
    :if ([ $MkTmpfs ] = false) do={
      :return false;
    }
  }

  :onerror Err {
    /file/add type="directory" name=$Path;
    $WaitForFile $Path;
  } do={
    $LogPrint warning $0 ("Making directory '" . $Path . "' failed: " . $Err);
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

# parse key value store
:set ParseKeyValueStore do={
  :local Source $1;

  :if ([ :pick $Source 0 1 ] = "{") do={
    :do {
      :return [ :deserialize from=json $Source ];
    } on-error={ }
  }

  :if ([ :typeof $Source ] != "array") do={
    :set Source [ :tostr $1 ];
  }
  :local Result ({});
  :foreach KeyValue in=[ :toarray $Source ] do={
    :if ([ :find $KeyValue "=" ]) do={
      :local Key [ :pick $KeyValue 0 [ :find $KeyValue "=" ] ];
      :local Value [ :pick $KeyValue ([ :find $KeyValue "=" ] + 1) [ :len $KeyValue ] ];
      :if ($Value="true") do={ :set Value true; }
      :if ($Value="false") do={ :set Value false; }
      :set ($Result->$Key) $Value;
    } else={
      :set ($Result->$KeyValue) true;
    }
  }
  :return $Result;
}

# print lines with trailing carriage return
:set PrettyPrint do={
  :put [ :tocrlf [ :tostr $1 ] ];
}

# strip protocol from from url string
:set ProtocolStrip do={
  :local Input [ :tostr $1 ];

  :local Pos [ :find $Input "://" ];
  :if ([ :typeof $Pos ] = "nil") do={
    :return $Input;
  }
  :return [ :pick $Input ($Pos + 3) [ :len $Input ] ];
}

# delay a random amount of seconds
:set RandomDelay do={
  :local Time [ :tonum $1 ];
  :local Unit [ :tostr $2 ];

  :global EitherOr;
  :global GetRandomNumber;
  :global MAX;

  :if ($Time = 0) do={
    :return false;
  }

  :delay ([ $MAX 10 [ $GetRandomNumber ([ :tonsec [ :totime ($Time . [ $EitherOr $Unit "s" ]) ] ] / 1000000) ] ] . "ms");
}

# check for required RouterOS version
:set RequiredRouterOS do={
  :local Caller   [ :tostr $1 ];
  :local Required [ :tostr $2 ];
  :local Warn     [ :tostr $3 ];

  :global IfThenElse;
  :global LogPrint;
  :global VersionToNum;

  :if (!($Required ~ "^\\d+\\.\\d+((alpha|beta|rc|\\.)\\d+|)\$")) do={
    $LogPrint error $0 ("No valid RouterOS version: " . $Required);
    :return false;
  }

  :if ([ $VersionToNum $Required ] > [ $VersionToNum [ /system/package/update/get installed-version ] ]) do={
    :if ($Warn = "true") do={
      $LogPrint warning $0 ("This " . [ $IfThenElse ([ :pick $Caller 0 ] = ("\$")) "function" "script" ] . \
        " '" . $Caller . "' (at least specific functionality) requires RouterOS " . $Required . ". Please update!");
    }
    :return false;
  }
  :return true;
}

# remove directory
:set RmDir do={
  :local DirName [ :tostr $1 ];

  :global FileGet;
  :global LogPrint;

  $LogPrint debug $0 ("Removing directory: ". $DirName);

  :local DirVal [ $FileGet $DirName ];
  :if ($DirVal = false) do={
    $LogPrint debug $0 ("... which does not exist.");
    :return true;
  }

  :if ($DirVal->"type" != "directory") do={
    $LogPrint error $0 ("Directory '" . $DirName . "' is not a directory.");
    :return false;
  }

  :onerror Err {
    /file/remove $DirName;
  } do={
    $LogPrint error $0 ("Removing directory '" . $DirName . "' failed: " . $Err);
    :return false;
  }
  :return true;
}

# remove file
:set RmFile do={
  :local FileName [ :tostr $1 ];

  :global FileGet;
  :global LogPrint;

  $LogPrint debug $0 ("Removing file: ". $FileName);

  :local FileVal [ $FileGet $FileName ];
  :if ($FileVal = false) do={
    $LogPrint debug $0 ("... which does not exist.");
    :return true;
  }

  :if ($FileVal->"type" = "directory" || $FileVal->"type" = "disk") do={
    $LogPrint error $0 ("File '" . $FileName . "' is not a file.");
    :return false;
  }

  :onerror Err {
    /file/remove $FileName;
  } do={
    $LogPrint error $0 ("Removing file '" . $FileName . "' failed: " . $Err);
    :return false;
  }
  :return true;
}

# check if script is run from terminal
:set ScriptFromTerminal do={
  :local Script [ :tostr $1 ];

  :global LogPrint;
  :global ScriptLock;

  :if ([ $ScriptLock $Script ] = false) do={
    :return false;
  }

  :foreach Job in=[ /system/script/job/find where script=$Script ] do={
    :set Job [ /system/script/job/get $Job ];
    :while ([ :typeof ($Job->"parent") ] = "id") do={
      :set Job [ /system/script/job/get [ find where .id=($Job->"parent") ] ];
    }
    :if (($Job->"type") = "login") do={
      $LogPrint debug $0 ("Script " . $Script . " started from terminal.");
      :return true;
    }
  }

  $LogPrint debug $0 ("Script " . $Script . " NOT started from terminal.");
  :return false;
}

# install new scripts, update existing scripts
:set ScriptInstallUpdate do={ :onerror Err {
  :local Scripts    [ :toarray $1 ];
  :local NewComment [ :tostr   $2 ];

  :global CommitId;
  :global CommitInfo;
  :global ExpectedConfigVersion;
  :global GlobalConfigReady;
  :global GlobalFunctionsReady;
  :global Identity;
  :global IDonate;
  :global NoNewsAndChangesNotification;
  :global ScriptUpdatesBaseUrl;
  :global ScriptUpdatesCRLF;
  :global ScriptUpdatesUrlSuffix;

  :global CertificateAvailable;
  :global EitherOr;
  :global FetchUserAgentStr;
  :global Grep;
  :global IfThenElse;
  :global LogPrint;
  :global LogPrintOnce;
  :global ParseKeyValueStore;
  :global RequiredRouterOS;
  :global SendNotification2;
  :global SymbolForNotification;
  :global ValidateSyntax;

  :if ([ $CertificateAvailable "ISRG Root X2" ] = false) do={
    $LogPrint warning $0 ("Downloading certificate failed, trying without.");
  }

  :foreach Script in=$Scripts do={
    :if ([ :len [ /system/script/find where name=$Script ] ] = 0) do={
      $LogPrint info $0 ("Adding new script: " . $Script);
      /system/script/add name=$Script owner=$Script source="#!rsc by RouterOS\n" comment=$NewComment;
    }
  }

  :local CommitIdBefore $CommitId;
  :local ExpectedConfigVersionBefore $ExpectedConfigVersion;
  :local ReloadGlobal false;
  :local DeviceMode [ /system/device-mode/get ];

  :local CheckSums ({});
  :do {
    :local Url ($ScriptUpdatesBaseUrl . "checksums.json" . $ScriptUpdatesUrlSuffix);
    $LogPrint debug $0 ("Fetching checksums from url: " . $Url);
    :set CheckSums [ :deserialize from=json ([ /tool/fetch check-certificate=yes-without-crl \
      http-header-field=({ [ $FetchUserAgentStr $0 ] }) $Url output=user as-value ]->"data") ];
  } on-error={ }

  :foreach Script in=[ /system/script/find where source~"^#!rsc by RouterOS\r?\n" ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local ScriptInfo [ $ParseKeyValueStore ($ScriptVal->"comment") ];
    :local SourceNew;

    :foreach Scheduler in=[ /system/scheduler/find where on-event~("\\b" . $ScriptVal->"name" . "\\b") ] do={
      :local SchedulerVal [ /system/scheduler/get $Scheduler ];
      :if ($ScriptVal->"policy" != $SchedulerVal->"policy") do={
        $LogPrint warning $0 ("Policies differ for script '" . $ScriptVal->"name" . \
          "' and its scheduler '" . $SchedulerVal->"name" . "'!");
      }
    }

    :do {
      :if ($ScriptInfo->"ignore" = true) do={
        $LogPrint debug $0 ("Ignoring script '" . $ScriptVal->"name" . "', as requested.");
        :error true;
      }

      :local CheckSum ($CheckSums->($ScriptVal->"name"));
      :if ([ :len ($ScriptInfo->"base-url") ] = 0 && [ :len ($ScriptInfo->"url-suffix") ] = 0 && \
           [ :convert transform=md5 to=hex [ :tolf ($ScriptVal->"source") ] ] = $CheckSum) do={
        $LogPrint debug $0 ("Checksum for script '" . $ScriptVal->"name" . "' matches, ignoring.");
        :error true;
      }

      :if ([ :len ($ScriptInfo->"certificate") ] > 0) do={
        :if ([ $CertificateAvailable ($ScriptInfo->"certificate") ] = false) do={
          $LogPrint warning $0 ("Downloading certificate failed, trying without.");
        }
      }

      :onerror Err {
        :local BaseUrl [ $EitherOr ($ScriptInfo->"base-url") $ScriptUpdatesBaseUrl ];
        :local UrlSuffix [ $EitherOr ($ScriptInfo->"url-suffix") $ScriptUpdatesUrlSuffix ];
        :local Url ($BaseUrl . $ScriptVal->"name" . ".rsc" . $UrlSuffix);
        $LogPrint debug $0 ("Fetching script '" . $ScriptVal->"name" . "' from url: " . $Url);
        :local Result [ /tool/fetch check-certificate=yes-without-crl \
          http-header-field=({ [ $FetchUserAgentStr $0 ] }) $Url output=user as-value ];
        :if ($Result->"status" = "finished") do={
          :set SourceNew [ :tolf ($Result->"data") ];
        }
      } do={
        $LogPrint warning $0 ("Failed fetching script '" . $ScriptVal->"name" . "': " . $Err);
        :if ($ScriptVal->"source" = "#!rsc by RouterOS\n") do={
          $LogPrint warning $0 ("Removing dummy. Typo on installation?");
          /system/script/remove $Script;
        }
        :error false;
      }

      :if ([ :len $SourceNew ] = 0) do={
        $LogPrint debug $0 ("No update for script '" . $ScriptVal->"name" . "'.");
        :error false;
      }

      :local SourceCRLF [ :tocrlf $SourceNew ];
      :if ($SourceNew = $ScriptVal->"source" || $SourceCRLF = $ScriptVal->"source") do={
        $LogPrint debug $0 ("Script '" .  $ScriptVal->"name" . "' did not change.");
        :error false;
      }

      :if ([ :pick $SourceNew 0 18 ] != "#!rsc by RouterOS\n") do={
        $LogPrint warning $0 ("Looks like new script '" . $ScriptVal->"name" . \
            "' is not valid (missing shebang). Ignoring!");
        :error false;
      }

      :local RequiredROS ([ $ParseKeyValueStore [ $Grep $SourceNew ("\23 requires RouterOS, ") ] ]->"version");
      :if ([ $RequiredRouterOS $0 [ $EitherOr $RequiredROS "0.0" ] false ] = false) do={
        $LogPrintOnce warning $0 ("The script '" . $ScriptVal->"name" . "' requires RouterOS " . \
            $RequiredROS . ", which is not met by your installation. Ignoring!");
        :error false;
      }

      :local RequiredDM [ $ParseKeyValueStore [ $Grep $SourceNew ("\23 requires device-mode, ") ] ];
      :local MissingDM ({});
      :foreach Feature,Value in=$RequiredDM do={
        :if ([ :typeof ($DeviceMode->$Feature) ] = "bool" && ($DeviceMode->$Feature) = false) do={
          :set MissingDM ($MissingDM, $Feature);
        }
      }
      :if ([ :len $MissingDM ] > 0) do={
        $LogPrintOnce warning $0 ("The script '" . $ScriptVal->"name" . "' requires disabled " . \
            "device-mode features (" . [ :tostr $MissingDM ] . "). Ignoring!");
        :error false;
      }

      :if ([ $ValidateSyntax $SourceNew ] = false) do={
        $LogPrint warning $0 ("Syntax validation for script '" . $ScriptVal->"name" . "' failed! Ignoring!");
        :error false;
      }

      $LogPrint info $0 ("Updating script: " . $ScriptVal->"name");
      /system/script/set owner=($ScriptVal->"name") \
          source=[ $IfThenElse ($ScriptUpdatesCRLF = true) $SourceCRLF $SourceNew ] $Script;
      :if ($ScriptVal->"name" = "global-config" || \
           $ScriptVal->"name" = "global-functions" || \
           $ScriptVal->"name" ~ ("^mod/.")) do={
        :set ReloadGlobal true;
      }
    } on-error={ }
  }

  :if ($ReloadGlobal = true) do={
    $LogPrint info $0 ("Reloading global configuration and functions.");
    :set GlobalConfigReady false;
    :set GlobalFunctionsReady false;
    :delay 1s;

    :onerror Err {
      /system/script/run global-config;
      /system/script/run global-functions;
    } do={
      $LogPrint error $0 ("Reloading global configuration and functions failed! " . $Err);
    }
  }

  :if ($CommitId != "unknown" && $CommitIdBefore != $CommitId) do={
    $LogPrint info $0 ("Updated to commit: " . $CommitInfo . "/" . [ :pick $CommitId 0 8 ]);
  }

  :if ($ExpectedConfigVersionBefore > $ExpectedConfigVersion) do={
    $LogPrint warning $0 ("The configuration version decreased from " . \
      $ExpectedConfigVersionBefore . " to " . $ExpectedConfigVersion . \
      ". Installed an older version?");
  }

  :if ($ExpectedConfigVersionBefore < $ExpectedConfigVersion) do={
    :global GlobalConfigChanges;
    :global GlobalConfigMigration;
    :local ChangeLogCode;

    :onerror Err {
      :local Url ($ScriptUpdatesBaseUrl . "news-and-changes.rsc" . $ScriptUpdatesUrlSuffix);
      $LogPrint debug $0 ("Fetching news, changes and migration: " . $Url);
      :local Result [ /tool/fetch check-certificate=yes-without-crl \
        http-header-field=({ [ $FetchUserAgentStr $0 ] }) $Url output=user as-value ];
      :if ($Result->"status" = "finished") do={
        :set ChangeLogCode ($Result->"data");
      }
    } do={
      $LogPrint warning $0 ("Failed fetching news, changes and migration: " . $Err);
    }

    :if ([ :len $ChangeLogCode ] > 0) do={
      :if ([ $ValidateSyntax $ChangeLogCode ] = true) do={
        :onerror Err {
          [ :parse $ChangeLogCode ];
        } do={
          $LogPrint warning $0 ("The changelog failed to run: " . $Err);
        }
      } else={
        $LogPrint warning $0 ("The changelog failed syntax validation!");
      }
    }

    :if ([ :len $GlobalConfigMigration ] > 0) do={
      :for I from=($ExpectedConfigVersionBefore + 1) to=$ExpectedConfigVersion do={
        :local Migration ($GlobalConfigMigration->[ :tostr $I ]);
        :do {
          :if ([ :typeof $Migration ] != "str") do={
            $LogPrint debug $0 ("Migration code for change " . $I . " is not available.");
            :error false;
          }

          :if ([ $ValidateSyntax $Migration ] = false) do={
            $LogPrint warning $0 ("Migration code for change " . $I . " failed syntax validation!");
            :error false;
          }

          $LogPrint info $0 ("Applying migration for change " . $I . ": " . $Migration);
          :onerror Err {
            [ :parse $Migration ];
          } do={
            $LogPrint warning $0 ("Migration code for change " . $I . " failed to run: " . $Err);
          }
        } on-error={ }
      }
    }

    :local NotificationMessage ("The configuration version on " . $Identity . " increased " . \
       "to " . $ExpectedConfigVersion . ", current configuration may need modification. " . \
       "Please review and update global-config-overlay, then re-run global-config.");
    $LogPrint info $0 ($NotificationMessage);

    :if ([ :len $GlobalConfigChanges ] > 0) do={
      :set NotificationMessage ($NotificationMessage . "\n\nChanges:");
      :for I from=($ExpectedConfigVersionBefore + 1) to=$ExpectedConfigVersion do={
        :local Change ($GlobalConfigChanges->[ :tostr $I ]);
        :set NotificationMessage ($NotificationMessage . "\n " . \
            [ $SymbolForNotification "pushpin" "*" ] . $Change);
        $LogPrint info $0 ("Change " . $I . ": " . $Change);
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
        :set Link "https://rsc.eworm.de/#donate";
      }

      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification "pushpin" ] . "News and configuration changes"); \
        message=$NotificationMessage; link=$Link });
    }

    :set GlobalConfigChanges;
    :set GlobalConfigMigration;
  }
} do={
  :global ExitError; $ExitError false $0 $Err;
} }

# lock script against multiple invocation
:set ScriptLock do={
  :local Script  [ :tostr  $1 ];
  :local WaitMax [ :totime $2 ];

  :global GetRandom20CharAlNum;
  :global IfThenElse;
  :global LogPrint;

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

  :if ([ :typeof $WaitMax ] = "nil" ) do={
    :set WaitMax 0s;
  }

  :if ([ :len [ /system/script/find where name=$Script ] ] = 0) do={
    $LogPrint error $0 ("A script named '" . $Script . "' does not exist!");
    :error false;
  }

  :if ([ $JobCount $Script ] = 0) do={
    $LogPrint error $0 ("No script '" . $Script . "' is running!");
    :error false;
  }

  :if ([ $TicketCount $Script ] >= [ $JobCount $Script ]) do={
    $LogPrint error $0 ("More tickets than running scripts '" . $Script . "', resetting!");
    :set ($ScriptLockOrder->$Script) ({});
    /system/script/job/remove [ find where script=$Script ];
  }

  :local MyTicket [ $GetRandom20CharAlNum 6 ];
  $AddTicket $Script $MyTicket;

  :local WaitInterval ($WaitMax / 20);
  :local WaitTime $WaitMax;
  :while ($WaitTime > 0 && \
      ([ $IsFirstTicket $Script $MyTicket ] = false || \
      [ $TicketCount $Script ] < [ $JobCount $Script ])) do={
    :set WaitTime ($WaitTime - $WaitInterval);
    :delay $WaitInterval;
  }

  :if ([ $IsFirstTicket $Script $MyTicket ] = true && \
      [ $TicketCount $Script ] = [ $JobCount $Script ]) do={
    $RemoveTicket $Script $MyTicket;
    $CleanupTickets $Script;
    :return true;
  }

  $RemoveTicket $Script $MyTicket;
  $LogPrint debug $0 ("Script '" . $Script . "' started more than once" . \
    [ $IfThenElse ($WaitTime < $WaitMax) " and timed out waiting for lock" "" ] . "...");
  :return false;
}

# send notification via NotificationFunctions - expects at least two string arguments
:set SendNotification do={ :onerror Err {
  :global SendNotification2;

  $SendNotification2 ({ origin=$0; subject=$1; message=$2; link=$3; silent=$4 });
} do={
  :global ExitError; $ExitError false $0 $Err;
} }

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
  :local Name [ :tostr $1 ];

  :global LogPrintOnce;

  :global SymbolsExtra;

  :local Symbols ({
    "abacus"="\F0\9F\A7\AE";
    "alarm-clock"="\E2\8F\B0";
    "arrow-down"="\E2\AC\87";
    "arrow-up"="\E2\AC\86";
    "calendar"="\F0\9F\93\85";
    "card-file-box"="\F0\9F\97\83";
    "chart-decreasing"="\F0\9F\93\89";
    "chart-increasing"="\F0\9F\93\88";
    "cloud"="\E2\98\81";
    "cross-mark"="\E2\9D\8C";
    "earth"="\F0\9F\8C\8D";
    "fire"="\F0\9F\94\A5";
    "floppy-disk"="\F0\9F\92\BE";
    "gear"="\E2\9A\99";
    "heart"="\E2\99\A5";
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
    "smiley-partying-face"="\F0\9F\A5\B3";
    "smiley-smiling-face"="\E2\98\BA";
    "smiley-winking-face-with-tongue"="\F0\9F\98\9C";
    "sparkles"="\E2\9C\A8";
    "speech-balloon"="\F0\9F\92\AC";
    "star"="\E2\AD\90";
    "warning-sign"="\E2\9A\A0";
    "white-heavy-check-mark"="\E2\9C\85"
  }, $SymbolsExtra);

  :if ([ :len ($Symbols->$Name) ] = 0) do={
    $LogPrintOnce warning $0 ("No symbol available for name '" . $Name . "'!");
    :return "";
  }

  :return (($Symbols->$Name) . "\EF\B8\8F");
}

# return symbol for notification
:set SymbolForNotification do={
  :global NotificationsWithSymbols;
  :global SymbolByUnicodeName;
  :global IfThenElse;

  :if ($NotificationsWithSymbols != true) do={
    :return [ $IfThenElse ([ :len $2 ] > 0) ([ :tostr $2 ] . " ") "" ];
  }
  :local Return "";
  :foreach Symbol in=[ :toarray $1 ] do={
    :set Return ($Return . [ $SymbolByUnicodeName $Symbol ]);
  }
  :return ($Return . " ");
}

# convert line endings, UNIX -> DOS
:set Unix2Dos do={
  :return [ :tocrlf [ :tostr $1 ] ];
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

  :global LogPrint;

  :onerror Err {
    [ :parse (":local Validate do={\n" . $Code . "\n}") ];
  } do={
    $LogPrint debug $0 ("Valdation failed: " . $Err);
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
  :foreach I in={ "zero"; "alpha"; "beta"; "rc" } do={
    :set Input [ $CharacterReplace $Input $I ("," . $I . ",") ];
  }

  :foreach Value in=([ :toarray $Input ], 0) do={
    :local Num [ :tonum $Value ];
    :if ($Multi = 0x100) do={
      :if ([ :typeof $Num ] = "num") do={
        :set Return ($Return + 0xff00);
        :set Multi ($Multi / 0x100);
      } else={
        :if ($Value = "zero") do={ }
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
  :global MAX;

  :set FileName [ $CleanFilePath $FileName ];
  :local Delay ([ $MAX [ $EitherOr $WaitTime 2s ] 100ms ] / 9);

  :do {
    :retry {
      /file/get $FileName;
      :return true;
    } delay=$Delay max=10;
  } on-error={ }

  :while ([ :len [ /file/find where name=$FileName ] ] > 0) do={
    :do {
      /file/get $FileName;
      :return true;
    } on-error={ }
    :delay $Delay;
    :set Delay ($Delay * 3 / 2);
  }

  :return false;
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
    :onerror Err {
      /system/script/run $Script;
    } do={
      $LogPrint error $0 ("Module '" . $ScriptVal->"name" . "' failed to run: " . $Err);
    }
  } else={
    $LogPrint error $0 ("Module '" . $ScriptVal->"name" . "' failed syntax validation, skipping.");
  }
}

# Log success
:local Resource [ /system/resource/get ];
$LogPrintOnce info $ScriptName ("Loaded on " . $Resource->"board-name" . \
  " with RouterOS " . $Resource->"version" . ".");

# signal we are ready
:set GlobalFunctionsReady true;
