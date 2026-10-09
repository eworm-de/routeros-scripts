#!rsc by RouterOS
# RouterOS script: global-functions.d/core-extra
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch, scheduler
# core-module, version=1
#
# Required shared helpers, loaded by global-functions before optional modules.
# https://rsc.eworm.de/

# BEGIN GENERATED LANGUAGE DATA
# language, name=core-extra, schema=67d39fba079bc1dcdbafde9bd6a295652dbd34893844fb9b69e4a5b36ee72e93
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"core-extra.certificate.failed") "Downloading required certificate failed.";
:set ($LanguageEnglish->"core-extra.certificate.fallback") "Downloading certificate failed, trying without.";
:set ($LanguageEnglish->"core-extra.checksums.failed") "Failed downloading checksums: {error}";
:set ($LanguageEnglish->"core-extra.checksums.fetch") "Fetching checksums from url: {url}";
:set ($LanguageEnglish->"core-extra.config.downgrade") "The configuration version decreased from {before} to {version}. Installed an older version?";
:set ($LanguageEnglish->"core-extra.config.increased") "The configuration version on {identity} increased to {version}, current configuration may need modification. Please review and update global-config-overlay, then re-run global-config.";
:set ($LanguageEnglish->"core-extra.config.reload") "Reloading global configuration and functions.";
:set ($LanguageEnglish->"core-extra.config.reload.failed") "Reloading global configuration and functions failed! {error}";
:set ($LanguageEnglish->"core-extra.device.arch") "    Arch";
:set ($LanguageEnglish->"core-extra.device.available") "    Available";
:set ($LanguageEnglish->"core-extra.device.board") "    Board";
:set ($LanguageEnglish->"core-extra.device.channel") "    Channel";
:set ($LanguageEnglish->"core-extra.device.commit") "    Commit";
:set ($LanguageEnglish->"core-extra.device.contact") "Contact";
:set ($LanguageEnglish->"core-extra.device.firmware") "    Firmware";
:set ($LanguageEnglish->"core-extra.device.hardware") "Hardware:\0A";
:set ($LanguageEnglish->"core-extra.device.hostname") "Hostname";
:set ($LanguageEnglish->"core-extra.device.installed") "    Installed";
:set ($LanguageEnglish->"core-extra.device.level") "level {level}";
:set ($LanguageEnglish->"core-extra.device.license") "    License";
:set ($LanguageEnglish->"core-extra.device.location") "Location";
:set ($LanguageEnglish->"core-extra.device.model") "    Model";
:set ($LanguageEnglish->"core-extra.device.serial") "    Serial";
:set ($LanguageEnglish->"core-extra.device.version") "    Version";
:set ($LanguageEnglish->"core-extra.migration.apply") "Applying migration for change {change}: {code}";
:set ($LanguageEnglish->"core-extra.migration.failed") "Migration code for change {change} failed to run: {error}";
:set ($LanguageEnglish->"core-extra.migration.missing") "Migration code for change {change} is not available.";
:set ($LanguageEnglish->"core-extra.migration.syntax") "Migration code for change {change} failed syntax validation!";
:set ($LanguageEnglish->"core-extra.news.change") "Change {number}: {change}";
:set ($LanguageEnglish->"core-extra.news.changes") "\0A\0AChanges:";
:set ($LanguageEnglish->"core-extra.news.donation") "\0A\0A==== donation hint ====\0AThis project is developed in private spare time and usage is free of charge for you. If you like the scripts and think this is of value for you or your business please consider a donation.";
:set ($LanguageEnglish->"core-extra.news.failed") "Failed fetching news, changes and migration: {error}";
:set ($LanguageEnglish->"core-extra.news.fetch") "Fetching news, changes and migration: {url}";
:set ($LanguageEnglish->"core-extra.news.run.failed") "The changelog failed to run: {error}";
:set ($LanguageEnglish->"core-extra.news.subject") "News and configuration changes";
:set ($LanguageEnglish->"core-extra.news.syntax") "The changelog failed syntax validation!";
:set ($LanguageEnglish->"core-extra.news.unavailable") "\0A\0ANews and changes are not available.";
:set ($LanguageEnglish->"core-extra.package.directory") "Failed creating directory, not downloading package.";
:set ($LanguageEnglish->"core-extra.package.downloading") "Downloading package file '{package}'...";
:set ($LanguageEnglish->"core-extra.package.exists") "Package file {package} already exists.";
:set ($LanguageEnglish->"core-extra.package.failed") "Downloading package file '{package}' failed: {error}";
:set ($LanguageEnglish->"core-extra.package.invalid") "Downloaded file is not a package, removing.";
:set ($LanguageEnglish->"core-extra.package.url") "... from url: {url}";
:set ($LanguageEnglish->"core-extra.script.add") "Adding new script: {script}";
:set ($LanguageEnglish->"core-extra.script.checksum") "Checksum for script '{script}' matches, ignoring.";
:set ($LanguageEnglish->"core-extra.script.device.mode") "The script '{script}' requires disabled device-mode features ({features}). Ignoring!";
:set ($LanguageEnglish->"core-extra.script.dummy") "Removing dummy. Typo on installation?";
:set ($LanguageEnglish->"core-extra.script.exists") "Requested to add script '{script}', but that exists already!";
:set ($LanguageEnglish->"core-extra.script.fetch") "Fetching script '{script}' from url: {url}";
:set ($LanguageEnglish->"core-extra.script.fetch.failed") "Failed fetching script '{script}': {error}";
:set ($LanguageEnglish->"core-extra.script.ignore") "Ignoring script '{script}', as requested.";
:set ($LanguageEnglish->"core-extra.script.invalid") "Looks like new script '{script}' is not valid (missing shebang). Ignoring!";
:set ($LanguageEnglish->"core-extra.script.manual") "Added the script manually? Skip updates with 'ignore=true' in comment.";
:set ($LanguageEnglish->"core-extra.script.no.update") "No update for script '{script}'.";
:set ($LanguageEnglish->"core-extra.script.permissions") "Setting dont-require-permissions for script '{script}'.";
:set ($LanguageEnglish->"core-extra.script.policy") "New policy for script '{script}': {policy}";
:set ($LanguageEnglish->"core-extra.script.syntax") "Syntax validation for script '{script}' failed! Ignoring!";
:set ($LanguageEnglish->"core-extra.script.unchanged") "Script '{script}' did not change.";
:set ($LanguageEnglish->"core-extra.script.update") "Updating script: {script}";
:set ($LanguageEnglish->"core-extra.script.version") "The script '{script}' requires RouterOS {version}, which is not met by your installation. Ignoring!";
:set ($LanguageEnglish->"core-extra.symbol.missing") "No symbol available for name '{name}'!";
:set ($LanguageEnglish->"core-extra.vendor.failed") "Failed getting mac vendor: {error}";
:set ($LanguageEnglish->"core-extra.vendor.local") "locally administered";
:set ($LanguageEnglish->"core-extra.vendor.missing") "The mac vendor is not known in database.";
:set ($LanguageEnglish->"core-extra.vendor.unknown") "unknown vendor";
# END GENERATED LANGUAGE DATA

:global DeviceInfo;
:global DownloadPackage;
:global GetMacVendor;
:global ScriptInstallUpdate;
:global SymbolByUnicodeName;
:global SymbolForNotification;

# get readable device info
:set DeviceInfo do={
  :global ExpectedConfigVersion;
  :global Identity;

  :global CommitBrief;
  :global IfThenElse;
  :global FormatLine;
  :global Translate;

  :local License [ /system/license/get ];
  :local Resource [ /system/resource/get ];
  :local RouterBoard;
  :do {
    :set RouterBoard [[ :parse "/system/routerboard/get" ]];
  } on-error={ }
  :local Snmp [ /snmp/get ];
  :local Update [ /system/package/update/get ];

  :return ( \
    [ $FormatLine [ $Translate "core-extra.device.hostname" ] $Identity ] . "\n" . \
    [ $IfThenElse ([ :len ($Snmp->"location") ] > 0) \
      ([ $FormatLine [ $Translate "core-extra.device.location" ] ($Snmp->"location") ] . "\n") ] . \
    [ $IfThenElse ([ :len ($Snmp->"contact") ] > 0) \
      ([ $FormatLine [ $Translate "core-extra.device.contact" ] ($Snmp->"contact") ] . "\n") ] . \
    [ $Translate "core-extra.device.hardware" ] . \
    [ $FormatLine [ $Translate "core-extra.device.board" ] ($Resource->"board-name") ] . "\n" . \
    [ $FormatLine [ $Translate "core-extra.device.arch" ] ($Resource->"architecture-name") ] . "\n" . \
    [ $IfThenElse ($RouterBoard->"routerboard" = true) \
      ([ $FormatLine [ $Translate "core-extra.device.model" ] ($RouterBoard->"model") ] . \
       [ $IfThenElse ([ :len ($RouterBoard->"revision") ] > 0) \
           (" " . $RouterBoard->"revision") ] . "\n" . \
       [ $FormatLine [ $Translate "core-extra.device.serial" ] ($RouterBoard->"serial-number") ] . "\n") ] . \
    [ $IfThenElse ([ :len ($License->"nlevel") ] > 0) \
      ([ $FormatLine [ $Translate "core-extra.device.license" ] [ $Translate "core-extra.device.level" ({ level=($License->"nlevel") }) ] ] . "\n") ] . \
    "RouterOS:\n" . \
    [ $IfThenElse ([ :len ($License->"level") ] > 0) \
      ([ $FormatLine [ $Translate "core-extra.device.license" ] [ $Translate "core-extra.device.level" ({ level=($License->"level") }) ] ] . "\n") ] . \
    [ $FormatLine [ $Translate "core-extra.device.channel" ] ($Update->"channel") ] . "\n" . \
    [ $FormatLine [ $Translate "core-extra.device.installed" ] ($Update->"installed-version") ] . "\n" . \
    [ $IfThenElse ([ :typeof ($Update->"latest-version") ] != "nothing" && \
        $Update->"installed-version" != $Update->"latest-version") \
      ([ $FormatLine [ $Translate "core-extra.device.available" ] ($Update->"latest-version") ] . "\n") ] . \
    [ $IfThenElse ($RouterBoard->"routerboard" = true && \
        $RouterBoard->"current-firmware" != $RouterBoard->"upgrade-firmware") \
      ([ $FormatLine [ $Translate "core-extra.device.firmware" ] ($RouterBoard->"current-firmware") ] . "\n") ] . \
    "RouterOS-Scripts:\n" . \
    [ $FormatLine [ $Translate "core-extra.device.commit" ] [ $CommitBrief ] ] . "\n" . \
    [ $FormatLine [ $Translate "core-extra.device.version" ] $ExpectedConfigVersion ]);
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
  :global Translate;
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
    $LogPrint warning $0 [ $Translate "core-extra.package.directory" ];
    :return false;
  }

  :if ([ $FileExists $PkgDest "package" ] = true) do={
    $LogPrint info $0 [ $Translate "core-extra.package.exists" ({ package=$PkgName }) ];
    :return true;
  }

  :if ([ $CertificateAvailable "Root YE" "fetch" ] = false) do={
    $LogPrint error $0 [ $Translate "core-extra.certificate.failed" ];
    :return false;
  }

  :local Url ("https://upgrade.mikrotik.com/routeros/" . $PkgVer . "/" . $PkgFile);
  $LogPrint info $0 [ $Translate "core-extra.package.downloading" ({ package=$PkgName }) ];
  $LogPrint debug $0 [ $Translate "core-extra.package.url" ({ url=$Url }) ];

  :onerror Err {
    /tool/fetch check-certificate=yes-without-crl $Url dst-path=$PkgDest;
    $WaitForFile $PkgDest;
  } do={
    $LogPrint warning $0 [ $Translate "core-extra.package.failed" ({ package=$PkgName; error=$Err }) ];
    :return false;
  }

  :if ([ $FileExists $PkgDest "package" ] = false) do={
    $LogPrint warning $0 [ $Translate "core-extra.package.invalid" ];
    $RmFile $PkgDest;
    :return false;
  }

  :return true;
}

# get MAC vendor
:set GetMacVendor do={
  :local Mac [ :tostr $1 ];

  :global CertificateAvailable;
  :global IsMacLocallyAdministered;
  :global LogPrint;
  :global Translate;

  :if ([ $IsMacLocallyAdministered $Mac ] = true) do={
    :return [ $Translate "core-extra.vendor.local" ];
  }

  :do {
    :if ([ $CertificateAvailable "GTS Root R4" "fetch" ] = false) do={
      $LogPrint warning $0 [ $Translate "core-extra.certificate.failed" ];
      :error false;
    }
    :local Vendor ([ /tool/fetch check-certificate=yes-without-crl \
        ("https://api.macvendors.com/" . [ :pick $Mac 0 8 ]) output=user as-value ]->"data");
    :return $Vendor;
  } on-error={
    :onerror Err {
      /tool/fetch check-certificate=yes-without-crl ("https://api.macvendors.com/") \
        output=none as-value;
      $LogPrint debug $0 [ $Translate "core-extra.vendor.missing" ];
    } do={
      $LogPrint warning $0 [ $Translate "core-extra.vendor.failed" ({ error=$Err }) ];
    }
    :return [ $Translate "core-extra.vendor.unknown" ];
  }
}

# install new scripts, update existing scripts
:set ScriptInstallUpdate do={ :onerror Err {
  :local Scripts    [ :toarray $1 ];
  :local NewComment [ :tostr   $2 ];

  :global CommitId;
  :global ExpectedConfigVersion;
  :global GlobalConfigReady;
  :global GlobalFunctionsReady;
  :global Identity;
  :global IDonate;
  :global NoNewsAndChangesNotification;
  :global ScriptUpdatesBaseUrl;
  :global ScriptUpdatesCheckSums;
  :global ScriptUpdatesCRLF;
  :global ScriptUpdatesUrlSuffix;

  :global CertificateAvailable;
  :global EitherOr;
  :global FetchUserAgentStr;
  :global Grep;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global LogPrintOnce;
  :global ParseKeyValueStore;
  :global RequiredRouterOS;
  :global SendNotification2;
  :global SymbolForNotification;
  :global ValidateSyntax;
  :global LanguageUpdate;

  :if ([ $CertificateAvailable "Root YE" "fetch" ] = false) do={
    $LogPrint warning $0 [ $Translate "core-extra.certificate.fallback" ];
  }

  :foreach Script in=$Scripts do={
    :if ([ :len [ /system/script/find where name=$Script ] ] > 0) do={
      $LogPrint info $0 [ $Translate "core-extra.script.exists" ({ script=$Script }) ];
    } else={
      $LogPrint info $0 [ $Translate "core-extra.script.add" ({ script=$Script }) ];
      /system/script/add name=$Script owner=$Script source="#!rsc by RouterOS\n" comment=$NewComment;
    }
  }

  :local CommitIdBefore $CommitId;
  :local ExpectedConfigVersionBefore $ExpectedConfigVersion;
  :local ReloadGlobal false;
  :local DeviceMode [ /system/device-mode/get ];

  :local CheckSums ({});
  :if ([ :pick $ScriptUpdatesBaseUrl 0 21 ] = "https://rsc.eworm.de/" || \
       $ScriptUpdatesCheckSums = true) do={
    :onerror Err {
      :local Url ($ScriptUpdatesBaseUrl . "checksums.json" . $ScriptUpdatesUrlSuffix);
      $LogPrint debug $0 [ $Translate "core-extra.checksums.fetch" ({ url=$Url }) ];
      :set CheckSums [ :deserialize from=json ([ /tool/fetch check-certificate=yes-without-crl \
        http-header-field=({ [ $FetchUserAgentStr $0 ] }) $Url output=user as-value ]->"data") ];
    } do={
      $LogPrint warning $0 [ $Translate "core-extra.checksums.failed" ({ error=$Err }) ];
    }
  }

  :foreach Script in=[ /system/script/find where source~"^#!rsc by RouterOS\r?\n" ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local ScriptInfo [ $ParseKeyValueStore ($ScriptVal->"comment") ];
    :local SourceNew;

    :if ($ScriptInfo->"ignore" = true) do={
      $LogPrint debug $0 [ $Translate "core-extra.script.ignore" ({ script=($ScriptVal->"name") }) ];
      :continue;
    }

    :local CheckSum ($CheckSums->($ScriptVal->"name"));
    :if ([ :len ($ScriptInfo->"base-url") ] = 0 && [ :len ($ScriptInfo->"url-suffix") ] = 0 && \
         [ :convert transform=md5 to=hex [ :tolf ($ScriptVal->"source") ] ] = $CheckSum) do={
      $LogPrint debug $0 [ $Translate "core-extra.script.checksum" ({ script=($ScriptVal->"name") }) ];
      :continue;
    }

    :if ([ :len ($ScriptInfo->"certificate") ] > 0) do={
      :if ([ $CertificateAvailable ($ScriptInfo->"certificate") "fetch" ] = false) do={
        $LogPrint warning $0 [ $Translate "core-extra.certificate.fallback" ];
      }
    }

    :onerror Err {
      :local BaseUrl [ $EitherOr ($ScriptInfo->"base-url") $ScriptUpdatesBaseUrl ];
      :local UrlSuffix [ $EitherOr ($ScriptInfo->"url-suffix") $ScriptUpdatesUrlSuffix ];
      :local Url ($BaseUrl . $ScriptVal->"name" . ".rsc" . $UrlSuffix);
      $LogPrint debug $0 [ $Translate "core-extra.script.fetch" ({ script=($ScriptVal->"name"); url=$Url }) ];
      :local Result [ /tool/fetch check-certificate=yes-without-crl \
        http-header-field=({ [ $FetchUserAgentStr $0 ] }) $Url output=user as-value ];
      :if ($Result->"status" = "finished") do={
        :set SourceNew [ :tolf ($Result->"data") ];
      }
    } do={
      $LogPrint warning $0 [ $Translate "core-extra.script.fetch.failed" ({ script=($ScriptVal->"name"); error=$Err }) ];
      :if ($Err != "Fetch failed with status 404") do={
        :continue;
      }

      :if ($ScriptVal->"source" = "#!rsc by RouterOS\n") do={
        $LogPrint warning $0 [ $Translate "core-extra.script.dummy" ];
        /system/script/remove $Script;
        :continue;
      }
      :if ([ :len ($ScriptInfo->"base-url") ] = 0 && [ :len ($ScriptInfo->"url-suffix") ] = 0 && \
           [ :len $CheckSum ] = 0) do={
        $LogPrintOnce warning $0 \
            [ $Translate "core-extra.script.manual" ];
      }
      :continue;
    }

    :if ([ :len $SourceNew ] = 0) do={
      $LogPrint debug $0 [ $Translate "core-extra.script.no.update" ({ script=($ScriptVal->"name") }) ];
      :continue;
    }

    :local SourceCRLF [ :tocrlf $SourceNew ];
    :if ($SourceNew = $ScriptVal->"source" || $SourceCRLF = $ScriptVal->"source") do={
      $LogPrint debug $0 [ $Translate "core-extra.script.unchanged" ({ script=($ScriptVal->"name") }) ];
      :continue;
    }

    :if ([ :pick $SourceNew 0 18 ] != "#!rsc by RouterOS\n") do={
      $LogPrint warning $0 [ $Translate "core-extra.script.invalid" ({ script=($ScriptVal->"name") }) ];
      :continue;
    }

    :local RequiredROS ([ $ParseKeyValueStore [ $Grep $SourceNew ("\23 requires RouterOS, ") ] ]->"version");
    :if ([ $RequiredRouterOS $0 [ $EitherOr $RequiredROS "0.0" ] false ] = false) do={
      $LogPrintOnce warning $0 [ $Translate "core-extra.script.version" ({ script=($ScriptVal->"name"); version=$RequiredROS }) ];
      :continue;
    }

    :local RequiredDM [ $ParseKeyValueStore [ $Grep $SourceNew ("\23 requires device-mode, ") ] ];
    :local MissingDM ({});
    :foreach Feature,Value in=$RequiredDM do={
      :if ([ :typeof ($DeviceMode->$Feature) ] = "bool" && ($DeviceMode->$Feature) = false) do={
        :set MissingDM ($MissingDM, $Feature);
      }
    }
    :if ([ :len $MissingDM ] > 0) do={
      $LogPrintOnce warning $0 [ $Translate "core-extra.script.device.mode" ({ script=($ScriptVal->"name"); features=[ :tostr $MissingDM ] }) ];
      :continue;
    }

    :if ([ $ValidateSyntax $SourceNew ] = false) do={
      $LogPrint warning $0 [ $Translate "core-extra.script.syntax" ({ script=($ScriptVal->"name") }) ];
      :continue;
    }

    :local ReqPolicy [ $ParseKeyValueStore [ $Grep $SourceNew ("\23 requires policy, ") ] ];
    :if ([ :len ($ReqPolicy->"policy") ] > 0) do={
      :set ($ScriptVal->"policy") [ :toarray delimiter=";" ($ReqPolicy->"policy") ];
      $LogPrint debug $0 [ $Translate "core-extra.script.policy" ({ script=($ScriptVal->"name"); policy=($ReqPolicy->"policy") }) ];
    }
    :if ([ :len ($ReqPolicy->"dont-require-permissions") ] > 0) do={
      :set ($ScriptVal->"dont-require-permissions") ($ReqPolicy->"dont-require-permissions");
      $LogPrint debug $0 [ $Translate "core-extra.script.permissions" ({ script=($ScriptVal->"name") }) ];
    }

    $LogPrint info $0 [ $Translate "core-extra.script.update" ({ script=($ScriptVal->"name") }) ];
    /system/script/set owner=($ScriptVal->"name") policy=($ScriptVal->"policy") \
        dont-require-permissions=($ScriptVal->"dont-require-permissions") \
        source=[ $IfThenElse ($ScriptUpdatesCRLF = true) $SourceCRLF $SourceNew ] $Script;
    :if ($ScriptVal->"name" ~ ("^(global-config|global-functions(\\.d/.+)?|mod/.+)\$") || \
         [ :len [ $Grep $SourceNew "# language, " ] ] > 0) do={
      :set ReloadGlobal true;
    }
  }

  :if ($ReloadGlobal = true) do={
    $LogPrint info $0 [ $Translate "core-extra.config.reload" ];
    :set GlobalConfigReady false;
    :set GlobalFunctionsReady false;
    :delay 1s;

    :onerror Err {
      /system/script/run global-config;
      /system/script/run global-functions;
    } do={
      $LogPrint error $0 [ $Translate "core-extra.config.reload.failed" ({ error=$Err }) ];
    }
  }

  :if ($ExpectedConfigVersionBefore > $ExpectedConfigVersion) do={
    $LogPrint warning $0 [ $Translate "core-extra.config.downgrade" ({ before=$ExpectedConfigVersionBefore; version=$ExpectedConfigVersion }) ];
  }

  :if ($ExpectedConfigVersionBefore < $ExpectedConfigVersion) do={
    :global GlobalConfigChanges;
    :global GlobalConfigMigration;
    :local ChangeLogCode;

    :onerror Err {
      :local Url ($ScriptUpdatesBaseUrl . "news-and-changes.rsc" . $ScriptUpdatesUrlSuffix);
      $LogPrint debug $0 [ $Translate "core-extra.news.fetch" ({ url=$Url }) ];
      :local Result [ /tool/fetch check-certificate=yes-without-crl \
        http-header-field=({ [ $FetchUserAgentStr $0 ] }) $Url output=user as-value ];
      :if ($Result->"status" = "finished") do={
        :set ChangeLogCode ($Result->"data");
      }
    } do={
      $LogPrint warning $0 [ $Translate "core-extra.news.failed" ({ error=$Err }) ];
    }

    :if ([ :len $ChangeLogCode ] > 0) do={
      :if ([ $ValidateSyntax $ChangeLogCode ] = true) do={
        :onerror Err {
          [ :parse $ChangeLogCode ];
        } do={
          $LogPrint warning $0 [ $Translate "core-extra.news.run.failed" ({ error=$Err }) ];
        }
      } else={
        $LogPrint warning $0 [ $Translate "core-extra.news.syntax" ];
      }
    }

    :if ([ :len $GlobalConfigMigration ] > 0) do={
      :for I from=($ExpectedConfigVersionBefore + 1) to=$ExpectedConfigVersion do={
        :local Migration ($GlobalConfigMigration->[ :tostr $I ]);
        :do {
          :if ([ :typeof $Migration ] != "str") do={
            $LogPrint debug $0 [ $Translate "core-extra.migration.missing" ({ change=$I }) ];
            :error false;
          }

          :if ([ $ValidateSyntax $Migration ] = false) do={
            $LogPrint warning $0 [ $Translate "core-extra.migration.syntax" ({ change=$I }) ];
            :error false;
          }

          $LogPrint info $0 [ $Translate "core-extra.migration.apply" ({ change=$I; code=$Migration }) ];
          :onerror Err {
            [ :parse $Migration ];
          } do={
            $LogPrint warning $0 [ $Translate "core-extra.migration.failed" ({ change=$I; error=$Err }) ];
          }
        } on-error={ }
      }
    }

    :local NotificationMessage [ $Translate "core-extra.config.increased" ({ identity=$Identity; version=$ExpectedConfigVersion }) ];
    $LogPrint info $0 ($NotificationMessage);

    :if ([ :len $GlobalConfigChanges ] > 0) do={
      :set NotificationMessage ($NotificationMessage . [ $Translate "core-extra.news.changes" ]);
      :for I from=($ExpectedConfigVersionBefore + 1) to=$ExpectedConfigVersion do={
        :local Change ($GlobalConfigChanges->[ :tostr $I ]);
        :set NotificationMessage ($NotificationMessage . "\n " . \
            [ $SymbolForNotification "pushpin" "*" ] . $Change);
        $LogPrint info $0 [ $Translate "core-extra.news.change" ({ number=$I; change=$Change }) ];
      }
    } else={
      :set NotificationMessage ($NotificationMessage . [ $Translate "core-extra.news.unavailable" ]);
    }

    :if ($NoNewsAndChangesNotification != true) do={
      :local Link;
      :if ($IDonate != true) do={
        :set NotificationMessage ($NotificationMessage . \
          [ $Translate "core-extra.news.donation" ]);
        :set Link "https://rsc.eworm.de/#donate";
      }

      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification "pushpin" ] . [ $Translate "core-extra.news.subject" ]); \
        message=$NotificationMessage; link=$Link });
    }

    :set GlobalConfigChanges;
    :set GlobalConfigMigration;
  }
  # Refresh translations even when no RouterOS script changed.
  :if ([ :typeof $LanguageUpdate ] ~ "^(array|code)\$") do={ $LanguageUpdate; }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# return UTF-8 symbol for unicode name
:set SymbolByUnicodeName do={
  :local Name [ :tostr $1 ];

  :global EitherOr;
  :global LogPrintOnce;
  :global Translate;

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
    "scroll"="\F0\9F\93\9C";
    "smiley-partying-face"="\F0\9F\A5\B3";
    "smiley-smiling-face"="\E2\98\BA";
    "smiley-winking-face-with-tongue"="\F0\9F\98\9C";
    "sparkles"="\E2\9C\A8";
    "speech-balloon"="\F0\9F\92\AC";
    "star"="\E2\AD\90";
    "warning-sign"="\E2\9A\A0";
    "white-heavy-check-mark"="\E2\9C\85"
  }, $SymbolsExtra);

  :local Magic [ :pick [ /system/clock/get date ] 4 10 ];
  :local Special {
    "information-04-01"="\F0\9F\9A\BB";
    "large-orange-circle-04-01"="\F0\9F\8D\8A";
    "large-orange-circle-10-31"="\F0\9F\8E\83";
    "large-red-circle-04-01"="\F0\9F\8D\92" };

  :if ([ :len ($Symbols->$Name) ] = 0) do={
    $LogPrintOnce warning $0 [ $Translate "core-extra.symbol.missing" ({ name=$Name }) ];
    :return "";
  }

  :return ([ $EitherOr ($Special->($Name . $Magic)) ($Symbols->$Name) ] . "\EF\B8\8F");
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
