#!rsc by RouterOS
# RouterOS script: check-routeros-update
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch, scheduler
#
# check for RouterOS update, send notification and/or install
# https://rsc.eworm.de/doc/check-routeros-update.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=check-routeros-update, schema=14553fc30c65433c4cbc9c9f368f0bc75852bc1581527c1a643b5cd4f7a70beb
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"check-routeros-update.all.log") "Installing ALL versions automatically, including {version}...";
:set ($LanguageEnglish->"check-routeros-update.all.message") "Installing ALL versions automatically, including {version}... Updating on {identity}...";
:set ($LanguageEnglish->"check-routeros-update.backup.partition") "Running from backup partition, refusing to act.";
:set ($LanguageEnglish->"check-routeros-update.canceled") "Canceled...";
:set ($LanguageEnglish->"check-routeros-update.checking") "Checking for updates...";
:set ($LanguageEnglish->"check-routeros-update.current") "System is already up to date.";
:set ($LanguageEnglish->"check-routeros-update.downgrade.log") "A different RouterOS version {version} is available for downgrade.";
:set ($LanguageEnglish->"check-routeros-update.downgrade.message") "A different RouterOS version {version} is available for {identity}, but it is a downgrade.\0A\0A{device}";
:set ($LanguageEnglish->"check-routeros-update.downgrade.sent") "Already sent the RouterOS downgrade notification for version {version}.";
:set ($LanguageEnglish->"check-routeros-update.downgrade.subject") "RouterOS version: {version}";
:set ($LanguageEnglish->"check-routeros-update.install.prompt") "Do you want to install RouterOS version {version}? [y/N]";
:set ($LanguageEnglish->"check-routeros-update.license.expired") "The license expired, upgrade is blocked.";
:set ($LanguageEnglish->"check-routeros-update.neighbor.log") "Seen a neighbor ({neighbor}) running version {version} from {channel}, updating...";
:set ($LanguageEnglish->"check-routeros-update.neighbor.message") "Seen a neighbor ({neighbor}) running version {version} from {channel}, updating on {identity}...";
:set ($LanguageEnglish->"check-routeros-update.patch.log") "Version {version} is a patch release, updating...";
:set ($LanguageEnglish->"check-routeros-update.patch.message") "Version {version} is a patch update for {channel}, updating on {identity}...";
:set ($LanguageEnglish->"check-routeros-update.safe.failed") "Failed receiving safe version for {channel}: {error}";
:set ($LanguageEnglish->"check-routeros-update.safe.log") "Version {version} is considered safe, updating...";
:set ($LanguageEnglish->"check-routeros-update.safe.message") "Version {version} is considered safe for {channel}, updating on {identity}...";
:set ($LanguageEnglish->"check-routeros-update.scheduler.exists") "A reboot for update is already scheduled.";
:set ($LanguageEnglish->"check-routeros-update.scheduler.stale") "Found a stale scheduler for reboot, removing.";
:set ($LanguageEnglish->"check-routeros-update.stable.changed") "Switched to channel 'stable', please re-run!";
:set ($LanguageEnglish->"check-routeros-update.stable.prompt") "This is a feature update in testing channel. Switch to channel 'stable'? [y/N]";
:set ($LanguageEnglish->"check-routeros-update.update.message") "A new RouterOS version {version} is available for {identity}.\0A\0A{device}";
:set ($LanguageEnglish->"check-routeros-update.update.sent") "Already sent the RouterOS update notification for version {version}.";
:set ($LanguageEnglish->"check-routeros-update.update.subject") "RouterOS update: {version}";
:set ($LanguageEnglish->"check-routeros-update.version.empty") "Received an empty version string from server.";
:set ($LanguageEnglish->"check-routeros-update.version.invalid") "The version '{version}' is not a valid version.";
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

  :global Identity;
  :global SafeUpdateAll;
  :global SafeUpdateNeighbor;
  :global SafeUpdateNeighborIdentity;
  :global SafeUpdatePatch;
  :global SafeUpdateUrl;
  :global SentRouterosUpdateNotification;

  :global DeviceInfo;
  :global EscapeForRegEx;
  :global FetchUserAgentStr;
  :global LogPrint;
  :global Translate;
  :global RebootForUpdate;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global VersionToNum;
  :global WaitFullyConnected;

  :local DoUpdate do={
    :local ScriptName [ :tostr $1 ];

    :if ([ :len [ /system/script/find where name="packages-update" ] ] > 0) do={
      /system/script/run packages-update;
    } else={
      /system/package/update/install without-paging;
    }
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :if (([ /system/license/get ]->"limited-upgrades") = true) do={
    $LogPrint warning $ScriptName [ $Translate "check-routeros-update.license.expired" ];
    :exit;
  }

  :if ([ :len [ /system/scheduler/find where name="running-from-backup-partition" ] ] > 0) do={
    $LogPrint warning $ScriptName [ $Translate "check-routeros-update.backup.partition" ];
    :exit;
  }

  $WaitFullyConnected;

  :if ([ :len [ /system/scheduler/find where name="_RebootForUpdate" ] ] > 0) do={
    :if ([ :typeof $RebootForUpdate ] = "nothing") do={
      $LogPrint info $ScriptName [ $Translate "check-routeros-update.scheduler.stale" ];
      /system/scheduler/remove "_RebootForUpdate";
    } else={
      $LogPrint info $ScriptName [ $Translate "check-routeros-update.scheduler.exists" ];
      :exit;
    }
  }

  $LogPrint debug $ScriptName [ $Translate "check-routeros-update.checking" ];
  /system/package/update/check-for-updates without-paging as-value;
  :local Update [ /system/package/update/get ];

  :if (($Update->"installed-version") = ($Update->"latest-version")) do={
    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      $LogPrint info $ScriptName [ $Translate "check-routeros-update.current" ];
    }
    :exit;
  }

  :if ([ :len ($Update->"latest-version") ] = 0) do={
    $LogPrint info $ScriptName [ $Translate "check-routeros-update.version.empty" ];
    :exit;
  }

  :local NumInstalled [ $VersionToNum ($Update->"installed-version") ];
  :local NumLatest [ $VersionToNum ($Update->"latest-version") ];
  :local BitMask [ $VersionToNum "255.255zero0" ];
  :local NumInstalledFeature ($NumInstalled & $BitMask);
  :local NumLatestFeature ($NumLatest & $BitMask);
  :local Link ("https://mikrotik.com/download/changelogs?versionFilter=" . \
      $Update->"latest-version" . "&channelFilter");

  :if ($NumLatest < [ $VersionToNum "7.0" ]) do={
    $LogPrint warning $ScriptName [ $Translate "check-routeros-update.version.invalid" \
        ({ version=($Update->"latest-version") }) ];
    :exit;
  }

  :if ($NumInstalled < $NumLatest) do={
    :if ($SafeUpdateAll ~ "^YES,? ?PLEASE!?\$") do={
      $LogPrint info $ScriptName [ $Translate "check-routeros-update.all.log" \
          ({ version=($Update->"latest-version") }) ];
      $SendNotification2 ({ origin=$ScriptName; silent=false; \
        subject=([ $SymbolForNotification "sparkles" ] . [ $Translate "check-routeros-update.update.subject" \
            ({ version=($Update->"latest-version") }) ]); \
        message=[ $Translate "check-routeros-update.all.message" \
            ({ version=($Update->"latest-version"); \
            identity=$Identity }) ]; \
            link=$Link });
      $DoUpdate $ScriptName;
      :exit;
    }

    :if ($SafeUpdatePatch = true && $NumInstalledFeature = $NumLatestFeature) do={
      $LogPrint info $ScriptName [ $Translate "check-routeros-update.patch.log" \
          ({ version=($Update->"latest-version") }) ];
      $SendNotification2 ({ origin=$ScriptName; silent=true; \
        subject=([ $SymbolForNotification "sparkles" ] . [ $Translate "check-routeros-update.update.subject" \
            ({ version=($Update->"latest-version") }) ]); \
        message=[ $Translate "check-routeros-update.patch.message" \
            ({ version=($Update->"latest-version"); \
            channel=($Update->"channel"); \
            identity=$Identity }) ]; \
            link=$Link });
      $DoUpdate $ScriptName;
      :exit;
    }

    :if ($SafeUpdateNeighbor = true) do={
      :local Neighbors [ /ip/neighbor/find where platform="MikroTik" identity~$SafeUpdateNeighborIdentity \
         version~("^" . [ $EscapeForRegEx ($Update->"latest-version") ] . "\\b") ];
      :if ([ :len $Neighbors ] > 0) do={
        :local Neighbor [ /ip/neighbor/get ($Neighbors->0) identity ];
        $LogPrint info $ScriptName [ $Translate "check-routeros-update.neighbor.log" \
            ({ neighbor=$Neighbor; \
            version=($Update->"latest-version"); \
            channel=($Update->"channel") }) ];
        $SendNotification2 ({ origin=$ScriptName; silent=true; \
          subject=([ $SymbolForNotification "sparkles" ] . [ $Translate "check-routeros-update.update.subject" \
              ({ version=($Update->"latest-version") }) ]); \
          message=[ $Translate "check-routeros-update.neighbor.message" \
              ({ neighbor=$Neighbor; \
              version=($Update->"latest-version"); \
              channel=($Update->"channel"); \
              identity=$Identity }) ]; \
              link=$Link });
        $DoUpdate $ScriptName;
        :exit;
      }
    }

    :if ([ :len $SafeUpdateUrl ] > 0) do={
      :local Result;
      :onerror Err {
        :set Result [ /tool/fetch check-certificate=yes-without-crl \
            ($SafeUpdateUrl . $Update->"channel" . "?installed=" . $Update->"installed-version" . \
            "&latest=" . $Update->"latest-version") http-header-field=({ [ $FetchUserAgentStr $ScriptName ] }) \
            output=user as-value ];
      } do={
        $LogPrint warning $ScriptName [ $Translate "check-routeros-update.safe.failed" \
            ({ channel=($Update->"channel"); \
            error=$Err }) ];
      }
      :if ($Result->"status" = "finished" && $Result->"data" = $Update->"latest-version") do={
        $LogPrint info $ScriptName [ $Translate "check-routeros-update.safe.log" \
            ({ version=($Update->"latest-version") }) ];
        $SendNotification2 ({ origin=$ScriptName; silent=true; \
          subject=([ $SymbolForNotification "sparkles" ] . [ $Translate "check-routeros-update.update.subject" \
              ({ version=($Update->"latest-version") }) ]); \
          message=[ $Translate "check-routeros-update.safe.message" \
              ({ version=($Update->"latest-version"); \
              channel=($Update->"channel"); \
              identity=$Identity }) ]; \
              link=$Link });
        $DoUpdate $ScriptName;
        :exit;
      }
    }

    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      :if (($Update->"channel") = "testing" && $NumInstalledFeature < $NumLatestFeature) do={
        :put [ $Translate "check-routeros-update.stable.prompt" ];
        :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          /system/package/update/set channel=stable;
          $LogPrint info $ScriptName [ $Translate "check-routeros-update.stable.changed" ];
          :exit;
        }
      }

      :put [ $Translate "check-routeros-update.install.prompt" ({ version=($Update->"latest-version") }) ];
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
        $DoUpdate $ScriptName;
        :exit;
      } else={
        :put [ $Translate "check-routeros-update.canceled" ];
      }
    }

    :if ($SentRouterosUpdateNotification = $Update->"latest-version") do={
      $LogPrint info $ScriptName [ $Translate "check-routeros-update.update.sent" \
          ({ version=($Update->"latest-version") }) ];
      :exit;
    }

    $SendNotification2 ({ origin=$ScriptName; silent=true; \
      subject=([ $SymbolForNotification "sparkles" ] . [ $Translate "check-routeros-update.update.subject" \
          ({ version=($Update->"latest-version") }) ]); \
      message=[ $Translate "check-routeros-update.update.message" \
          ({ version=($Update->"latest-version"); \
          identity=$Identity; \
          device=[ $DeviceInfo ] }) ]; \
          link=$Link });
    :set SentRouterosUpdateNotification ($Update->"latest-version");
  }

  :if ($NumInstalled > $NumLatest) do={
    :if ($SentRouterosUpdateNotification = $Update->"latest-version") do={
      $LogPrint info $ScriptName [ $Translate "check-routeros-update.downgrade.sent" \
          ({ version=($Update->"latest-version") }) ];
      :exit;
    }

    $SendNotification2 ({ origin=$ScriptName; silent=false; \
      subject=([ $SymbolForNotification "warning-sign" ] . [ $Translate "check-routeros-update.downgrade.subject" \
          ({ version=($Update->"latest-version") }) ]); \
      message=[ $Translate "check-routeros-update.downgrade.message" \
          ({ version=($Update->"latest-version"); \
          identity=$Identity; \
          device=[ $DeviceInfo ] }) ]; \
          link=$Link });
    $LogPrint info $ScriptName [ $Translate "check-routeros-update.downgrade.log" \
        ({ version=($Update->"latest-version") }) ];
    :set SentRouterosUpdateNotification ($Update->"latest-version");
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
