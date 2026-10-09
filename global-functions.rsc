#!rsc by RouterOS
# RouterOS script: global-functions
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch, scheduler
#
# global functions
# https://rsc.eworm.de/

# BEGIN GENERATED LANGUAGE DATA
# language, name=global-functions, schema=11ec766b1c116091e098b19755e3efe320ce083797063fbd31e6880667418d65
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"global-functions.certificate.chain") "Certificate chain for '{name}' is incomplete, missing '{issuer}'.";
:set ($LanguageEnglish->"global-functions.certificate.download") "Downloading and importing certificate with CommonName '{name}'.";
:set ($LanguageEnglish->"global-functions.certificate.failed") "Failed downloading certificate with CommonName '{name}'!";
:set ($LanguageEnglish->"global-functions.certificate.fallback") "Failed downloading certificate with CommonName '{name}' from repository! Trying fallback to mkcert.org...";
:set ($LanguageEnglish->"global-functions.certificate.flash.low") "This system has low free flash space but is configured to download certificate CRLs to system!";
:set ($LanguageEnglish->"global-functions.certificate.match.missing") "No matching certificate found for pattern '{pattern}'.";
:set ($LanguageEnglish->"global-functions.certificate.match.multiple") "Too many matching certificates found for pattern '{pattern}'.";
:set ($LanguageEnglish->"global-functions.certificate.multiple") "There are several certificates with CommonName '{name}'. Should be ok.";
:set ($LanguageEnglish->"global-functions.certificate.name.missing") "No CommonName given!";
:set ($LanguageEnglish->"global-functions.certificate.required") "Required certificate is not available.";
:set ($LanguageEnglish->"global-functions.certificate.still.unavailable") "Certificate with CommonName '{name}' still unavailable!";
:set ($LanguageEnglish->"global-functions.certificate.unavailable") "Certificate with CommonName '{name}' not available.";
:set ($LanguageEnglish->"global-functions.certificate.use.undefined") "The intended use is undefined!";
:set ($LanguageEnglish->"global-functions.directory.creating") "Making directory: {path}";
:set ($LanguageEnglish->"global-functions.directory.exists") "... which already exists.";
:set ($LanguageEnglish->"global-functions.directory.failed") "Making directory '{path}' failed: {error}";
:set ($LanguageEnglish->"global-functions.directory.remove.failed") "Removing directory '{path}' failed: {error}";
:set ($LanguageEnglish->"global-functions.directory.removing") "Removing directory: {path}";
:set ($LanguageEnglish->"global-functions.directory.type") "Directory '{path}' is not a directory.";
:set ($LanguageEnglish->"global-functions.error.function") "Function '{name}' exited with error.";
:set ($LanguageEnglish->"global-functions.error.function.detail") "Function '{name}' exited with error: {error}";
:set ($LanguageEnglish->"global-functions.error.script") "Script '{name}' exited with error.";
:set ($LanguageEnglish->"global-functions.error.script.detail") "Script '{name}' exited with error: {error}";
:set ($LanguageEnglish->"global-functions.fetch.directory.failed") "Failed creating directory!";
:set ($LanguageEnglish->"global-functions.fetch.failed") "Failed downloading from {url} - {error}";
:set ($LanguageEnglish->"global-functions.fetch.file.missing") "The file downloaded from {url} did not show up.";
:set ($LanguageEnglish->"global-functions.file.remove.failed") "Removing file '{file}' failed: {error}";
:set ($LanguageEnglish->"global-functions.file.removing") "Removing file: {file}";
:set ($LanguageEnglish->"global-functions.file.type") "File '{file}' is not a file.";
:set ($LanguageEnglish->"global-functions.language.cache.failed") "Could not cache language catalog; using it in memory.";
:set ($LanguageEnglish->"global-functions.language.fetch.failed") "Language catalog {group}: {error} Using cached translations or English.";
:set ($LanguageEnglish->"global-functions.language.https") "Language downloads require HTTPS.";
:set ($LanguageEnglish->"global-functions.language.incompatible") "Incompatible language catalog.";
:set ($LanguageEnglish->"global-functions.language.incomplete") "Language download incomplete.";
:set ($LanguageEnglish->"global-functions.language.invalid") "Invalid ScriptLanguage; using English.";
:set ($LanguageEnglish->"global-functions.language.message.invalid") "Invalid language message.";
:set ($LanguageEnglish->"global-functions.language.size") "Language catalog exceeds size limit.";
:set ($LanguageEnglish->"global-functions.language.update.failed") "Language update: {error}";
:set ($LanguageEnglish->"global-functions.loaded") "Loaded {commit}on {board} with RouterOS {version}.";
:set ($LanguageEnglish->"global-functions.lock.repeated") "Script '{script}' started more than once...";
:set ($LanguageEnglish->"global-functions.lock.script.missing") "A script named '{script}' does not exist!";
:set ($LanguageEnglish->"global-functions.lock.script.stopped") "No script '{script}' is running!";
:set ($LanguageEnglish->"global-functions.lock.tickets.reset") "More tickets than running scripts '{script}', resetting!";
:set ($LanguageEnglish->"global-functions.lock.timeout") "Script '{script}' started more than once and timed out waiting for lock...";
:set ($LanguageEnglish->"global-functions.log.once.crash") "The message is already in log, scripting subsystem may have crashed before!";
:set ($LanguageEnglish->"global-functions.log.unknown") "<unknown>";
:set ($LanguageEnglish->"global-functions.module.duplicate") "Duplicate required module: {module}";
:set ($LanguageEnglish->"global-functions.module.failed") "Module '{module}' failed to run: {error}";
:set ($LanguageEnglish->"global-functions.module.installing") "Installing required module: {module}";
:set ($LanguageEnglish->"global-functions.module.invalid") "Required module failed validation: {module}";
:set ($LanguageEnglish->"global-functions.module.syntax") "Module '{module}' failed syntax validation, skipping.";
:set ($LanguageEnglish->"global-functions.module.uninitialized") "Required module did not initialize: {module}";
:set ($LanguageEnglish->"global-functions.path.missing") "... which does not exist.";
:set ($LanguageEnglish->"global-functions.script.nonterminal") "Script {script} NOT started from terminal.";
:set ($LanguageEnglish->"global-functions.script.terminal") "Script {script} started from terminal.";
:set ($LanguageEnglish->"global-functions.severity.debug") "debug";
:set ($LanguageEnglish->"global-functions.severity.error") "error";
:set ($LanguageEnglish->"global-functions.severity.info") "info";
:set ($LanguageEnglish->"global-functions.severity.warning") "warning";
:set ($LanguageEnglish->"global-functions.syntax.failed") "Valdation failed: {error}";
:set ($LanguageEnglish->"global-functions.time.ntp.unsynced") "The ntp client is configured, but did not sync.";
:set ($LanguageEnglish->"global-functions.time.rtc") "No ntp client configured, relying on RTC for CHR free license and x86.";
:set ($LanguageEnglish->"global-functions.time.source.missing") "No time source configured! Returning gracefully...";
:set ($LanguageEnglish->"global-functions.tmpfs.creating") "Creating disk of type tmpfs.";
:set ($LanguageEnglish->"global-functions.tmpfs.enabled") "The tmpfs is disabled, enabling.";
:set ($LanguageEnglish->"global-functions.tmpfs.failed") "Creating disk of type tmpfs failed: {error}";
:set ($LanguageEnglish->"global-functions.version.function") "This function '{caller}' (at least specific functionality) requires RouterOS {version}. Please update!";
:set ($LanguageEnglish->"global-functions.version.invalid") "No valid RouterOS version: {version}";
:set ($LanguageEnglish->"global-functions.version.script") "This script '{caller}' (at least specific functionality) requires RouterOS {version}. Please update!";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:local ScriptName [ :jobname ];

# Git commit id & info, expected configuration version
:global CommitId "unknown";
:global CommitInfo "unknown";
:global ExpectedConfigVersion 147;

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
:global CommitBrief;
:global DeviceInfo;
:global Dos2Unix;
:global DownloadPackage;
:global EitherOr;
:global EscapeForRegEx;
:global ExitOnError;
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
:global NetMask4;
:global NetMask6;
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
  :local UseFor     [ :tostr $2 ];

  :global CertificateDownload;
  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;

  :if ([ :len $UseFor ] = 0) do={
    $LogPrint info $0 [ $Translate "global-functions.certificate.use.undefined" ];
    :set UseFor "undefined";
  }

  :if ([ /system/resource/get free-hdd-space ] < 8388608 && \
       [ /certificate/settings/get crl-download ] = true && \
       [ /certificate/settings/get crl-store ] = "system") do={
    $LogPrint warning $0 [ $Translate "global-functions.certificate.flash.low" ];
  }

  :if ([ :len $CommonName ] = 0) do={
    $LogPrint warning $0 [ $Translate "global-functions.certificate.name.missing" ];
    :return false;
  }

  :local CertSettings [ /certificate/settings/get ];
  :if ((($CertSettings->"builtin-trust-store") ~ $UseFor || \
        (($CertSettings->"builtin-trust-store") = "default" && \
         ($CertSettings->"current-defaults") ~ $UseFor) || \
        ($CertSettings->"builtin-trust-store") = "all") && \
       [ :len [ /certificate/builtin/find where common-name=$CommonName or unit=$CommonName ] ] > 0) do={
    :return true;
  }

  :if ([ :len [ /certificate/find where common-name=$CommonName or unit=$CommonName ] ] = 0) do={
    $LogPrint info $0 [ $Translate "global-functions.certificate.unavailable" \
        ({ name=$CommonName }) ];
    :if ([ $CertificateDownload $CommonName ] = false) do={
      :return false;
    }
  }

  :if ([ :len [ /certificate/find where common-name=$CommonName or unit=$CommonName ] ] > 1) do={
    $LogPrint info $0 [ $Translate "global-functions.certificate.multiple" \
        ({ name=$CommonName }) ];
    :return true;
  }

  :local CertVal [ /certificate/get [ find where common-name=$CommonName or unit=$CommonName ] ];
  :while (($CertVal->"akid") != "" && ($CertVal->"akid") != ($CertVal->"skid")) do={
    :if ([ :len [ /certificate/find where skid=($CertVal->"akid") ] ] = 0) do={
      :local IssuerCN ([ $ParseKeyValueStore ($CertVal->"issuer") ]->"CN");
      $LogPrint info $0 [ $Translate "global-functions.certificate.chain" \
          ({ name=$CommonName; issuer=[ :tostr $IssuerCN ] }) ];
      :if ([ $CertificateDownload $IssuerCN ] = false) do={
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

  :global CertificateNameByCN;
  :global CleanName;
  :global IfThenElse;
  :global FetchUserAgentStr;
  :global LogPrint;
  :global Translate;
  :global RmFile;
  :global WaitForFile;

  $LogPrint info $0 [ $Translate "global-functions.certificate.download" \
      ({ name=$CommonName }) ];
  :local FileName ([ $CleanName $CommonName ] . ".pem");
  :do {
    /tool/fetch check-certificate=yes-without-crl http-header-field=({ [ $FetchUserAgentStr $0 ] }) \
      ($ScriptUpdatesBaseUrl . "certs/" . $FileName . $ScriptUpdatesUrlSuffix) \
      dst-path=$FileName as-value;
    $WaitForFile $FileName;
  } on-error={
    $LogPrint warning $0 [ $Translate "global-functions.certificate.fallback" \
        ({ name=$CommonName }) ];
    :do {
      :local CertSettings [ /certificate/settings/get ];
      :if ([ :len [ /certificate/find where common-name="Root YE" ] ] = 0 && \
           !((($CertSettings->"builtin-trust-store") ~ "fetch" || \
              (($CertSettings->"builtin-trust-store") = "default" && \
               ($CertSettings->"current-defaults") ~ "fetch") || \
              ($CertSettings->"builtin-trust-store") = "all") && \
             [ :len [ /certificate/builtin/find where common-name="Root YE" ] ] > 0)) do={
        $LogPrint error $0 [ $Translate "global-functions.certificate.required" ];
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
      $LogPrint warning $0 [ $Translate "global-functions.certificate.failed" \
          ({ name=$CommonName }) ];
      :return false;
    }
  }

  /certificate/import file-name=$FileName passphrase="" as-value;
  :delay 1s;
  $RmFile $FileName;

  :if ([ :len [ /certificate/find where common-name=$CommonName or unit=$CommonName ] ] = 0) do={
    /certificate/remove [ find where name~("^" . $FileName . "_[0-9]+\$") ];
    $LogPrint warning $0 [ $Translate "global-functions.certificate.still.unavailable" \
        ({ name=$CommonName }) ];
    :return false;
  }

  :foreach Cert in=[ /certificate/find where name~("^" . $FileName . "_[0-9]+\$") ] do={
    $CertificateNameByCN [ $IfThenElse ([ /certificate/get $Cert unit ] = $CommonName) \
      $CommonName [ /certificate/get $Cert common-name ] ];
  }
  :return true;
}

# name a certificate by its common-name
:set CertificateNameByCN do={
  :local Match [ :tostr $1 ];

  :global CleanName;
  :global LogPrint;
  :global Translate;

  :local Cert [ /certificate/find where unit=$Match ];
  :if ([ :len $Cert ] = 1) do={
    /certificate/set $Cert name=[ $CleanName $Match ];
    :return true;
  }

  :set Cert [ /certificate/find where common-name=$Match or fingerprint=$Match or \
      name=$Match or (!(skid="") skid=$Match) ];
  :if ([ :len $Cert ] > 1) do={
    $LogPrint warning $0 [ $Translate "global-functions.certificate.match.multiple" ({ pattern=$Match }) ];
    :return false;
  }

  :if ([ :len $Cert ] = 0) do={
    $LogPrint warning $0 [ $Translate "global-functions.certificate.match.missing" ({ pattern=$Match }) ];
    :return false;
  }

  :local CommonName [ /certificate/get $Cert common-name ];
  /certificate/set $Cert name=[ $CleanName $CommonName ];
  :return true;
}

# multiply given character(s)
:set CharacterMultiply do={
  :local Str [ :tostr $1 ];
  :local Num [ :tonum $2 ];

  :if ($Num = 0) do={
    :return "";
  }

  :local Return "";
  :for I from=1 to=$Num do={
    :set Return ($Return . $Str);
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
    :if ([ :typeof [ :find "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" $Char ] ] = "nil") do={
      :if ([ :len $Return ] = 0 || \
           [ :pick $Return ([ :len $Return ] - 1) ] = "-") do={
        :continue;
      }
      :set Char "-";
    }
    :set Return ($Return . $Char);
  }
  :return $Return;
}

# return a brief commit description
:set CommitBrief do={
  :global CommitId;
  :global CommitInfo;

  :if ($CommitId = "unknown") do={
    :return "unknown";
  }

  :return ($CommitInfo . "/" . [ :pick $CommitId 0 8 ]);
}


# convert line endings, DOS -> UNIX
:set Dos2Unix do={
  :return [ :tolf [ :tostr $1 ] ];
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
:set ExitOnError do={
  :local Name   [ :tostr $1 ];
  :local Error  [ :tostr $2 ];

  :global IfThenElse;
  :global LogPrint;
  :global Translate;

  :local Message [ $Translate "global-functions.error.script" \
      ({ name=$Name }) ];
  :if ([ :pick $Name 0 1 ] = "\$") do={ :set Message [ $Translate "global-functions.error.function" \
      ({ name=$Name }) ]; };
  :if (!($Error ~ "^(|true|false)\$")) do={
    :set Message [ $Translate "global-functions.error.script.detail" \
        ({ name=$Name; error=$Error }) ];
    :if ([ :pick $Name 0 1 ] = "\$") do={ :set Message [ $Translate "global-functions.error.function.detail" \
        ({ name=$Name; error=$Error }) ]; };
  }
  $LogPrint error $Name $Message;
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
  :global Translate;
  :global MkDir;
  :global RmDir;
  :global RmFile;
  :global WaitForFile;

  :set CheckCert [ $IfThenElse ($CheckCert = "false") "no" "yes-without-crl" ];

  :local DirName ("tmpfs/" . [ $CleanName $ScriptName ]);
  :if ([ $MkDir $DirName ] = false) do={
    $LogPrint error $0 [ $Translate "global-functions.fetch.directory.failed" ];
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
    $LogPrint debug $0 [ $Translate "global-functions.fetch.failed" \
        ({ url=$Url; error=$Err }) ];
    $RmDir $DirName;
    :return false;
  }

  :if ([ $WaitForFile $FileName 5s ] = false) do={
    $LogPrint debug $0 [ $Translate "global-functions.fetch.file.missing" \
        ({ url=$Url }) ];
    :return false;
  }

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

  :global CommitBrief;
  :global IfThenElse;

  :local Resource [ /system/resource/get ];

  :return ("User-Agent: Mikrotik/" . $Resource->"version" . " " . $Resource->"architecture-name" . \
    " " . $Caller . "/Fetch (https://rsc.eworm.de/; " . [ $CommitBrief ] . ")");
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
    # Do *NOT* try :deserialize here to split lines. It can fail with
    # scripts, and it *does* fail with global-functions!
    :local Len [ :find $Input "\n" ];
    :local Line [ :pick $Input 0 $Len ];
    :if ([ :typeof [ :find $Line $Pattern ] ] = "num") do={
      :return $Line;
    }
    :set Input [ :pick $Input ($Len + 1) [ :len $Input ] ];
  } while=([ :len $Input ] > 0);

  :return [];
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
    :local I 1;
    :retry {
      :set I ($I ^ 1);
      :resolve ("low-ttl.eworm." . ({ "de"; "net" }->$I));
    } delay=50ms max=6;
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
  :global Translate;

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

    $LogPrintOnce warning $0 [ $Translate "global-functions.time.ntp.unsynced" ];
    :set IsTimeSyncResetNtp $Uptime;
    /system/ntp/client/set enabled=no;
    :delay 20ms;
    /system/ntp/client/set enabled=yes;
    :return false;
  }

  :if ([ /system/license/get ]->"level" = "free" || \
       [ /system/resource/get ]->"board-name" = "x86") do={
    $LogPrintOnce debug $0 [ $Translate "global-functions.time.rtc" ];
    :return true;
  }

  :if ([ /ip/cloud/get update-time ] = true) do={
    :if ([ :typeof [ /ip/cloud/get public-address ] ] = "ip") do={
      :set IsTimeSyncCached true;
      :return true;
    }
    :return false;
  }

  $LogPrintOnce debug $0 [ $Translate "global-functions.time.source.missing" ];
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
  :global Translate;

  :local Debug [ $EitherOr ($PrintDebugOverride->$Name) $PrintDebug ];

  :local PrintSeverity do={
    :global TerminalColorOutput;
    :global Translate;
    :local Label $1;
    :if ($1 = "debug") do={ :set Label [ $Translate "global-functions.severity.debug" ]; };
    :if ($1 = "info") do={ :set Label [ $Translate "global-functions.severity.info" ]; };
    :if ($1 = "warning") do={ :set Label [ $Translate "global-functions.severity.warning" ]; };
    :if ($1 = "error") do={ :set Label [ $Translate "global-functions.severity.error" ]; };


    :if ($TerminalColorOutput != true) do={
      :return $Label;
    }

    :local Color { debug=96; info=97; warning=93; error=91 };
    :return ("\1B[" . $Color->$1 . "m" . $Label . "\1B[0m");
  }

  :local Log ([ $EitherOr $Name [ $Translate "global-functions.log.unknown" ] ] . ": " . $Message);
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
  :global Translate;

  :global LogPrintOnceMessages;
  :global LogPrintOnceCrashMessages;

  :if ([ :typeof $LogPrintOnceMessages ] = "nothing") do={
    :set LogPrintOnceMessages ({});
  }

  :if ($LogPrintOnceMessages->$Message = 1) do={
    :return false;
  }

  :if ([ :len [ /log/find where message=($Name . ": " . $Message) ] ] > 0) do={
    :local Alert [ $Translate "global-functions.log.once.crash" ];
    :if ([ :typeof $LogPrintOnceCrashMessages ] != "array") do={ :set LogPrintOnceCrashMessages ({}); }
    :set ($LogPrintOnceCrashMessages->$Alert) true;
    $LogPrint warning $0 $Alert;
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
  :global Translate;
  :global RmDir;
  :global WaitForFile;

  :local MkTmpfs do={
    :global LogPrint;
    :global Translate;
    :global WaitForFile;

    :local TmpFs [ /disk/find where slot=tmpfs type=tmpfs ];
    :if ([ :len $TmpFs ] = 1) do={
      :if ([ /disk/get $TmpFs disabled ] = true) do={
        $LogPrint info $0 [ $Translate "global-functions.tmpfs.enabled" ];
        /disk/enable $TmpFs;
      }
      :return true;
    }

    $LogPrint info $0 [ $Translate "global-functions.tmpfs.creating" ];
    $RmDir "tmpfs";
    :onerror Err {
      /disk/add slot=tmpfs type=tmpfs tmpfs-max-size=([ /system/resource/get total-memory ] / 3);
      $WaitForFile "tmpfs";
    } do={
      $LogPrint warning $0 [ $Translate "global-functions.tmpfs.failed" \
          ({ error=$Err }) ];
      :return false;
    }
    :return true;
  }

  :set Path [ $CleanFilePath $Path ];

  :if ($Path = "") do={
    :return true;
  }

  $LogPrint debug $0 [ $Translate "global-functions.directory.creating" \
      ({ path=$Path }) ];

  :local PathVal [ $FileGet $Path ];
  :if ($PathVal->"type" = "directory") do={
    $LogPrint debug $0 [ $Translate "global-functions.directory.exists" ];
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
    $LogPrint warning $0 [ $Translate "global-functions.directory.failed" \
        ({ path=$Path; error=$Err }) ];
    :return false;
  }

  :return true;
}

# return an IPv4 netmask for CIDR
:set NetMask4 do={
  :local CIDR [ :tonum $1 ];

  :return ((255.255.255.255 << (32 - $CIDR)) & 255.255.255.255);
}

# return an IPv6 netmask for CIDR
:set NetMask6 do={
  :local CIDR [ :tonum $1 ];

  :return (((~::) << (128 - $CIDR)) & (~::));
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
  :global Translate;
  :global VersionToNum;

  :if (!($Required ~ "^\\d+\\.\\d+((alpha|beta|rc|\\.)\\d+|)\$")) do={
    $LogPrint error $0 [ $Translate "global-functions.version.invalid" \
        ({ version=$Required }) ];
    :return false;
  }

  :if ([ $VersionToNum $Required ] > [ $VersionToNum [ /system/package/update/get installed-version ] ]) do={
    :if ($Warn = "true") do={
      :local Message [ $Translate "global-functions.version.script" \
          ({ caller=$Caller; version=$Required }) ];
      :if ([ :pick $Caller 0 ] = "\$") do={ :set Message [ $Translate "global-functions.version.function" \
          ({ caller=$Caller; version=$Required }) ]; };
      $LogPrint warning $0 $Message;
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
  :global Translate;

  $LogPrint debug $0 [ $Translate "global-functions.directory.removing" \
      ({ path=$DirName }) ];

  :local DirVal [ $FileGet $DirName ];
  :if ($DirVal = false) do={
    $LogPrint debug $0 [ $Translate "global-functions.path.missing" ];
    :return true;
  }

  :if ($DirVal->"type" != "directory") do={
    $LogPrint error $0 [ $Translate "global-functions.directory.type" \
        ({ path=$DirName }) ];
    :return false;
  }

  :onerror Err {
    /file/remove [ find where name=$DirName ];
  } do={
    :if (!($Err ~ "no such item")) do={
      $LogPrint error $0 [ $Translate "global-functions.directory.remove.failed" \
          ({ path=$DirName; error=$Err }) ];
      :return false;
    }
  }
  :return true;
}

# remove file
:set RmFile do={
  :local FileName [ :tostr $1 ];

  :global FileGet;
  :global LogPrint;
  :global Translate;

  $LogPrint debug $0 [ $Translate "global-functions.file.removing" \
      ({ file=$FileName }) ];

  :local FileVal [ $FileGet $FileName ];
  :if ($FileVal = false) do={
    $LogPrint debug $0 [ $Translate "global-functions.path.missing" ];
    :return true;
  }

  :if ($FileVal->"type" = "directory" || $FileVal->"type" = "disk") do={
    $LogPrint error $0 [ $Translate "global-functions.file.type" \
        ({ file=$FileName }) ];
    :return false;
  }

  :onerror Err {
    /file/remove [ find where name=$FileName ];
  } do={
    :if (!($Err ~ "no such item")) do={
      $LogPrint error $0 [ $Translate "global-functions.file.remove.failed" \
          ({ file=$FileName; error=$Err }) ];
      :return false;
    }
  }
  :return true;
}

# check if script is run from terminal
:set ScriptFromTerminal do={
  :local Script [ :tostr $1 ];

  :global LogPrint;
  :global Translate;
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
      $LogPrint debug $0 [ $Translate "global-functions.script.terminal" \
          ({ script=$Script }) ];
      :return true;
    }
  }

  $LogPrint debug $0 [ $Translate "global-functions.script.nonterminal" \
      ({ script=$Script }) ];
  :return false;
}


# lock script against multiple invocation
:set ScriptLock do={
  :local Script  [ :tostr  $1 ];
  :local WaitMax [ :totime $2 ];

  :global GetRandom20CharAlNum;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;

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
    $LogPrint error $0 [ $Translate "global-functions.lock.script.missing" \
        ({ script=$Script }) ];
    :error false;
  }

  :if ([ $JobCount $Script ] = 0) do={
    $LogPrint error $0 [ $Translate "global-functions.lock.script.stopped" \
        ({ script=$Script }) ];
    :error false;
  }

  :if ([ $TicketCount $Script ] >= [ $JobCount $Script ]) do={
    $LogPrint error $0 [ $Translate "global-functions.lock.tickets.reset" \
        ({ script=$Script }) ];
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
  :local Message [ $Translate "global-functions.lock.repeated" \
      ({ script=$Script }) ];
  :if ($WaitTime < $WaitMax) do={ :set Message [ $Translate "global-functions.lock.timeout" \
      ({ script=$Script }) ]; };
  $LogPrint debug $0 $Message;
  :return false;
}

# send notification via NotificationFunctions - expects at least two string arguments
:set SendNotification do={ :onerror Err {
  :global SendNotification2;

  $SendNotification2 ({ origin=$0; subject=$1; message=$2; link=$3; silent=$4 });
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
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



# convert line endings, UNIX -> DOS
:set Unix2Dos do={
  :return [ :tocrlf [ :tostr $1 ] ];
}

# basic syntax validation
:set ValidateSyntax do={
  :local Code [ :tostr $1 ];

  :global LogPrint;
  :global Translate;

  :onerror Err {
    [ :parse (":local Validate do={\n" . $Code . "\n}") ];
  } do={
    $LogPrint debug $0 [ $Translate "global-functions.syntax.failed" \
        ({ error=$Err }) ];
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

# BEGIN GENERATED LANGUAGE RUNTIME
# Discover catalog schemas from installed scripts, so unused features need no downloads.
:global LanguageSchemas ({});
:foreach Script in=[ /system/script/find ] do={
  :local Info [ $ParseKeyValueStore [ $Grep [ /system/script/get $Script source ] "# language, " ] ];
  :if ([ :len ($Info->"schema") ] = 64 && ($Info->"name") ~ "^[a-z0-9-]+\$") do={
    :set ($LanguageSchemas->($Info->"name")) ($Info->"schema");
  }
}
# Translation helpers. Embedded in global-functions.rsc by contrib/languages.py.
:global Translate;
:global LanguageUpdate;
:global LanguageEnglish;
:global LanguageMessages;
:global LanguageActive;

# Render placeholders once; parameter values are never evaluated or re-expanded.
:set Translate do={
  :local Key [ :tostr $1 ];
  :local Params $2;
  :global ScriptLanguage;
  :global LanguageEnglish;
  :global LanguageMessages;
  :global LanguageActive;

  :local English ($LanguageEnglish->$Key);
  :if ([ :typeof $English ] != "str") do={ :return $Key; }
  :local Text $English;
  :if ($LanguageActive = $ScriptLanguage && [ :typeof ($LanguageMessages->$Key) ] = "str") do={
    :set Text ($LanguageMessages->$Key);
  }
  :local Tokens do={
    :local Text $1;
    :local Names ({});
    :while ([ :len $Text ] > 0) do={
      :local Start [ :find $Text "{" ];
      :if ([ :typeof $Start ] = "nil") do={
        :if ([ :typeof [ :find $Text "}" ] ] != "nil") do={ :return false; }
        :return $Names;
      }
      :local End [ :find $Text "}" $Start ];
      :if ([ :typeof $End ] = "nil") do={ :return false; }
      :if ([ :typeof [ :find [ :pick $Text 0 $Start ] "}" ] ] != "nil") do={ :return false; }
      :local Name [ :pick $Text ($Start + 1) $End ];
      :if (!($Name ~ "^[a-z][a-z0-9_]*\$")) do={ :return false; }
      :set ($Names->$Name) true;
      :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
    }
    :return $Names;
  }
  :local EnglishTokens [ $Tokens $English ];
  :local TranslatedTokens [ $Tokens $Text ];
  :local Valid false;
  :if ([ :typeof $TranslatedTokens ] = "array" && \
       [ :len $EnglishTokens ] = [ :len $TranslatedTokens ]) do={
    :set Valid true;
    :foreach Name,Unused in=$EnglishTokens do={
      :if (($TranslatedTokens->$Name) != true) do={ :set Valid false; }
    }
  }
  :if ($Valid != true) do={ :set Text $English; }
  :local Result "";
  :while ([ :len $Text ] > 0) do={
    :local Start [ :find $Text "{" ];
    :if ([ :typeof $Start ] = "nil") do={ :return ($Result . $Text); }
    :local End [ :find $Text "}" $Start ];
    :if ([ :typeof $End ] = "nil") do={ :return $English; }
    :local Name [ :pick $Text ($Start + 1) $End ];
    :if ([ :typeof ($Params->$Name) ] = "nothing" || \
         [ :typeof ($Params->$Name) ] = "nil") do={ :return $English; }
    :set Result ($Result . [ :pick $Text 0 $Start ] . [ :tostr ($Params->$Name) ]);
    :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
  }
  :return $Result;
}

# Load a cached catalog before fetching. Never run downloaded text as code.
:set LanguageUpdate do={
  :global Translate;
  :global GlobalNotReadyMessage;
  :global ScriptLanguage;
  :global ScriptUpdatesBaseUrl;
  :global ScriptUpdatesUrlSuffix;
  :global LanguageSchemas;
  :global LanguageMessages;
  :global LanguageActive;
  :global LanguageUpdateRunning;

  :if ($LanguageUpdateRunning = true) do={ :return false; }
  :set LanguageUpdateRunning true;
  :local Locale $ScriptLanguage;
  :onerror Err {
    :if ($Locale = "en") do={
      :set LanguageMessages ({});
      :set LanguageActive "en";
      :set GlobalNotReadyMessage [ $Translate "global-config.not.ready" ];
      :set LanguageUpdateRunning false;
      :return true;
    }
    :if (!($Locale ~ "^[a-z][a-z](-[A-Z][A-Z])?\$")) do={
      :error [ $Translate "global-functions.language.invalid" ];
    }
    :if ([ :pick $ScriptUpdatesBaseUrl 0 8 ] != "https://") do={
      :error [ $Translate "global-functions.language.https" ];
    }
    :local ReadCatalog do={
      :global Translate;
      :local Body $1;
      :local Schema $2;
      :local Locale $3;
      :local Group $4;
      :if ([ :len $Body ] > 50000) do={ :error [ $Translate "global-functions.language.size" ]; }
      :local Catalog [ :deserialize from=json options=json.no-string-conversion $Body ];
      :if (($Catalog->"schema") != $Schema || ($Catalog->"language") != $Locale || \
           [ :typeof ($Catalog->"messages") ] != "array") do={
        :error [ $Translate "global-functions.language.incompatible" ];
      }
      :foreach Key,Value in=($Catalog->"messages") do={
        :if ([ :typeof $Value ] != "str" || \
             [ :pick $Key 0 ([ :len $Group ] + 1) ] != ($Group . ".")) do={
          :error [ $Translate "global-functions.language.message.invalid" ];
        }
      }
      :return ($Catalog->"messages");
    }
    :local AllMessages ({});
    :local Prefix "";
    :if ([ :len [ /file/find where name="flash" ] ] > 0) do={ :set Prefix "flash/"; }
    :foreach Group,Schema in=$LanguageSchemas do={
      :local Cache ($Prefix . "language-" . $Locale . "-" . $Group . ".json");
      :local Messages ({});
      :local Cached "";
      :local Files [ /file/find where name=$Cache ];
      :if ([ :len $Files ] = 1) do={
        :do {
          :set Cached [ /file/get $Files contents ];
          :set Messages [ $ReadCatalog $Cached $Schema $Locale $Group ];
        } on-error={ :set Cached ""; }
      }
      # Make cached text available while the network request is in progress.
      :foreach Key,Value in=$Messages do={ :set ($AllMessages->$Key) $Value; }
      :if ($ScriptLanguage = $Locale) do={
        :set LanguageMessages $AllMessages;
        :set LanguageActive $Locale;
      }
      :onerror FetchErr {
        :local Url ($ScriptUpdatesBaseUrl . "languages/" . $Locale . "/" . $Group . ".json" . $ScriptUpdatesUrlSuffix);
        :local Response [ /tool/fetch url=$Url check-certificate=yes-without-crl output=user as-value ];
        :if (($Response->"status") != "finished") do={ :error [ $Translate "global-functions.language.incomplete" ]; }
        :local Body ($Response->"data");
        :local NewMessages [ $ReadCatalog $Body $Schema $Locale $Group ];
        :set Messages $NewMessages;
        :if ($Body != $Cached) do={
          :do {
            :if ([ :len $Files ] = 0) do={
              /file/add name=$Cache contents=$Body;
            } else={ /file/set $Files contents=$Body; }
          } on-error={ :log warning [ $Translate "global-functions.language.cache.failed" ]; }
        }
      } do={
        :log warning [ $Translate "global-functions.language.fetch.failed" ({ group=$Group; error=$FetchErr }) ];
      }
      :foreach Key,Value in=$Messages do={ :set ($AllMessages->$Key) $Value; }
    }
    :if ($ScriptLanguage = $Locale) do={
      :set LanguageMessages $AllMessages;
      :set LanguageActive $Locale;
    }
  } do={ :log warning [ $Translate "global-functions.language.update.failed" ({ error=$Err }) ]; }
  :set GlobalNotReadyMessage [ $Translate "global-config.not.ready" ];
  :set LanguageUpdateRunning false;
  :return true;
}
# END GENERATED LANGUAGE RUNTIME

# Load the required shared helpers before optional modules. Existing installations
# acquire the dependency here when an older installer updates global-functions.
:local CoreModuleName "global-functions.d/core-extra";
:local CoreExportsValid do={
  :global Grep;
  :foreach Name in={ "DeviceInfo"; "DownloadPackage"; "GetMacVendor"; "ScriptInstallUpdate"; \
                    "SymbolByUnicodeName"; "SymbolForNotification" } do={
    :if ([ :len [ $Grep $1 (":set " . $Name . " do={") ] ] = 0) do={ :return false; }
  }
  :return true;
}
:local CoreModule [ /system/script/find where name=$CoreModuleName ];
:if ([ :len $CoreModule ] > 1) do={ :error [ $Translate "global-functions.module.duplicate" \
    ({ module=$CoreModuleName }) ]; }
:local CoreSource "";
:if ([ :len $CoreModule ] = 1) do={ :set CoreSource [ :tolf [ /system/script/get $CoreModule source ] ]; }
:local CoreInfo [ $ParseKeyValueStore [ $Grep $CoreSource "# core-module, " ] ];
:if (($CoreInfo->"version") != "1" || [ $CoreExportsValid $CoreSource ] != true || \
     [ $ValidateSyntax $CoreSource ] = false) do={
  :global ScriptUpdatesBaseUrl;
  :global ScriptUpdatesUrlSuffix;
  :local SourceInfo ({});
  :local Self [ /system/script/find where name=$ScriptName ];
  :if ([ :len $Self ] = 1) do={ :set SourceInfo [ $ParseKeyValueStore [ /system/script/get $Self comment ] ]; }
  :local BaseUrl [ $EitherOr ($SourceInfo->"base-url") $ScriptUpdatesBaseUrl ];
  :local UrlSuffix [ $EitherOr ($SourceInfo->"url-suffix") $ScriptUpdatesUrlSuffix ];
  :local Url ($BaseUrl . $CoreModuleName . ".rsc" . $UrlSuffix);
  $LogPrint info $ScriptName [ $Translate "global-functions.module.installing" \
      ({ module=$CoreModuleName }) ];
  :local Response [ /tool/fetch check-certificate=yes-without-crl output=user url=$Url as-value ];
  :set CoreSource [ :tolf ($Response->"data") ];
  :set CoreInfo [ $ParseKeyValueStore [ $Grep $CoreSource "# core-module, " ] ];
  :local RequiredROS ([ $ParseKeyValueStore [ $Grep $CoreSource "# requires RouterOS, " ] ]->"version");
  :if (($Response->"status") != "finished" || [ :pick $CoreSource 0 18 ] != "#!rsc by RouterOS\n" || \
       ($CoreInfo->"version") != "1" || [ $RequiredRouterOS $ScriptName $RequiredROS false ] != true || \
       [ $CoreExportsValid $CoreSource ] != true || \
       [ $ValidateSyntax $CoreSource ] != true) do={
    :error [ $Translate "global-functions.module.invalid" \
        ({ module=$CoreModuleName }) ];
  }
  :if ([ :len $CoreModule ] = 0) do={
    /system/script/add name=$CoreModuleName owner=$CoreModuleName source=$CoreSource;
    :set CoreModule [ /system/script/find where name=$CoreModuleName ];
  } else={ /system/script/set source=$CoreSource $CoreModule; }
}
:set DeviceInfo; :set DownloadPackage; :set GetMacVendor;
:set ScriptInstallUpdate; :set SymbolByUnicodeName; :set SymbolForNotification;
/system/script/run $CoreModule;
:if (!([ :typeof $ScriptInstallUpdate ] ~ "^(array|code)\$" && \
       [ :typeof $SymbolForNotification ] ~ "^(array|code)\$" && \
       [ :typeof $SymbolByUnicodeName ] ~ "^(array|code)\$" && \
       [ :typeof $DeviceInfo ] ~ "^(array|code)\$" && \
       [ :typeof $DownloadPackage ] ~ "^(array|code)\$" && \
       [ :typeof $GetMacVendor ] ~ "^(array|code)\$")) do={
  :error [ $Translate "global-functions.module.uninitialized" \
      ({ module=$CoreModuleName }) ];
}
# A freshly installed dependency was absent from the initial catalog discovery.
:local CoreLanguage [ $ParseKeyValueStore [ $Grep $CoreSource "# language, " ] ];
:if ([ :len ($CoreLanguage->"schema") ] = 64) do={
  :set ($LanguageSchemas->($CoreLanguage->"name")) ($CoreLanguage->"schema");
}

# load modules
:foreach Script in=[ /system/script/find where name ~ "^(global-functions\\.d|mod)/." name!=$CoreModuleName ] do={
  :local ScriptVal [ /system/script/get $Script ];
  :if ([ $ValidateSyntax ($ScriptVal->"source") ] = true) do={
    :onerror Err {
      /system/script/run $Script;
    } do={
      $LogPrint error $0 [ $Translate "global-functions.module.failed" \
          ({ module=($ScriptVal->"name"); error=$Err }) ];
    }
  } else={
    $LogPrint error $0 [ $Translate "global-functions.module.syntax" \
        ({ module=($ScriptVal->"name") }) ];
  }
}

# add (and fix) global scripts scheduler
/system/scheduler {
  :local OnEvent "/system/script { run global-config; run global-functions; }";
  :if ([ :len [ find where name="global-scripts" ] ] = 0) do={
    add name="global-scripts" start-time=startup;
  }
  set on-event=$OnEvent [ find where name="global-scripts" on-event!=$OnEvent ];
  enable [ find where name="global-scripts" disabled ];
}

# Log success
:local Resource [ /system/resource/get ];
$LogPrintOnce info $ScriptName [ $Translate "global-functions.loaded" \
    ({ commit=[ $IfThenElse ($CommitId != "unknown") ([ $CommitBrief ] . " ") "" ]; board=($Resource->"board-name"); version=($Resource->"version") }) ];

# signal we are ready
:set GlobalFunctionsReady true;

# Catalog downloads must not delay readiness or require internet at startup.
:execute { :global LanguageUpdate; $LanguageUpdate; };
