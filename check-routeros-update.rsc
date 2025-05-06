#!rsc by RouterOS
# RouterOS script: check-routeros-update
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, fetch, scheduler
#
# check for RouterOS update, send notification and/or install
# https://rsc.eworm.de/doc/check-routeros-update.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local ExitOK false;
:do {
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
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global VersionToNum;
  :global WaitFullyConnected;

  :local DoUpdate do={
    :local ScriptName [ :tostr $1 ];

    :global LogPrint;

    :if ([ :len [ /system/script/find where name="packages-update" ] ] > 0) do={
      /system/script/run packages-update;
    } else={
      /system/package/update/install without-paging;
    }
    $LogPrint info $ScriptName ("Waiting for system to reboot.");
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :if ([ :len [ /system/scheduler/find where name="running-from-backup-partition" ] ] > 0) do={
    $LogPrint warning $ScriptName ("Running from backup partition, refusing to act.");
    :set ExitOK true;
    :error false;
  }

  $WaitFullyConnected;

  :if ([ :len [ /system/scheduler/find where name="_RebootForUpdate" ] ] > 0) do={
    $LogPrint info $ScriptName ("A reboot for update is already scheduled.");
    :set ExitOK true;
    :error false;
  }

  $LogPrint debug $ScriptName ("Checking for updates...");
  /system/package/update/check-for-updates without-paging as-value;
  :local Update [ /system/package/update/get ];

  :if (($Update->"installed-version") = ($Update->"latest-version")) do={
    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      $LogPrint info $ScriptName ("System is already up to date.");
    }
    :set ExitOK true;
    :error true;
  }

  :if ([ :len ($Update->"latest-version") ] = 0) do={
    $LogPrint info $ScriptName ("Received an empty version string from server.");
    :set ExitOK true;
    :error false;
  }

  :local NumInstalled [ $VersionToNum ($Update->"installed-version") ];
  :local NumLatest [ $VersionToNum ($Update->"latest-version") ];
  :local BitMask [ $VersionToNum "255.255zero0" ];
  :local NumInstalledFeature ($NumInstalled & $BitMask);
  :local NumLatestFeature ($NumLatest & $BitMask);
  :local Link ("https://mikrotik.com/download/changelogs/" . $Update->"channel" . "-release-tree");

  :if ($NumLatest < [ $VersionToNum "7.0" ]) do={
    $LogPrint warning $ScriptName ("The version '" . ($Update->"latest-version") . "' is not a valid version.");
    :set ExitOK true;
    :error false;
  }

  :if ($NumInstalled < $NumLatest) do={
    :if ($SafeUpdateAll ~ "^YES,? ?PLEASE!?\$") do={
      $LogPrint info $ScriptName ("Installing ALL versions automatically, including " . \
        $Update->"latest-version" . "...");
      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
        message=("Installing ALL versions automatically, including " . $Update->"latest-version" . \
          "... Updating on " . $Identity . "..."); link=$Link; silent=true });
      $DoUpdate $ScriptName;
      :set ExitOK true;
      :error true;
    }

    :if ($SafeUpdatePatch = true && $NumInstalledFeature = $NumLatestFeature) do={
      $LogPrint info $ScriptName ("Version " . $Update->"latest-version" . " is a patch release, updating...");
      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
        message=("Version " . $Update->"latest-version" . " is a patch update for " . $Update->"channel" . \
          ", updating on " . $Identity . "..."); link=$Link; silent=true });
      $DoUpdate $ScriptName;
      :set ExitOK true;
      :error true;
    }

    :if ($SafeUpdateNeighbor = true) do={
      :local Neighbors [ /ip/neighbor/find where platform="MikroTik" identity~$SafeUpdateNeighborIdentity \
         version~("^" . [ $EscapeForRegEx ($Update->"latest-version") ] . "\\b") ];
      :if ([ :len $Neighbors ] > 0) do={
        :local Neighbor [ /ip/neighbor/get ($Neighbors->0) identity ];
        $LogPrint info $ScriptName ("Seen a neighbor (" . $Neighbor . ") running version " . \
          $Update->"latest-version" . " from " . $Update->"channel" . ", updating...");
        $SendNotification2 ({ origin=$ScriptName; \
          subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
          message=("Seen a neighbor (" . $Neighbor . ") running version " . $Update->"latest-version" . \
            " from " . $Update->"channel" . ", updating on " . $Identity . "..."); link=$Link; silent=true });
        $DoUpdate $ScriptName;
        :set ExitOK true;
        :error true;
      }
    }

    :if ([ :len $SafeUpdateUrl ] > 0) do={
      :local Result;
      :do {
        :set Result [ /tool/fetch check-certificate=yes-without-crl \
            ($SafeUpdateUrl . $Update->"channel" . "?installed=" . $Update->"installed-version" . \
            "&latest=" . $Update->"latest-version") http-header-field=({ [ $FetchUserAgentStr $ScriptName ] }) \
            output=user as-value ];
      } on-error={
        $LogPrint warning $ScriptName ("Failed receiving safe version for " . $Update->"channel" . ".");
      }
      :if ($Result->"status" = "finished" && $Result->"data" = $Update->"latest-version") do={
        $LogPrint info $ScriptName ("Version " . $Update->"latest-version" . " is considered safe, updating...");
        $SendNotification2 ({ origin=$ScriptName; \
          subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
          message=("Version " . $Update->"latest-version" . " is considered safe for " . $Update->"channel" . \
            ", updating on " . $Identity . "..."); link=$Link; silent=true });
        $DoUpdate $ScriptName;
        :set ExitOK true;
        :error true;
      }
    }

    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      :if (($Update->"channel") = "testing" && $NumInstalledFeature < $NumLatestFeature) do={
        :put ("This is a feature update in testing channel. Switch to channel 'stable'? [y/N]");
        :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          /system/package/update/set channel=stable;
          $LogPrint info $ScriptName ("Switched to channel 'stable', please re-run!");
          :set ExitOK true;
          :error true;
        }
      }

      :put ("Do you want to install RouterOS version " . $Update->"latest-version" . "? [y/N]");
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
        $DoUpdate $ScriptName;
        :set ExitOK true;
        :error true;
      } else={
        :put "Canceled...";
      }
    }

    :if ($SentRouterosUpdateNotification = $Update->"latest-version") do={
      $LogPrint info $ScriptName ("Already sent the RouterOS update notification for version " . \
          $Update->"latest-version" . ".");
      :set ExitOK true;
      :error true;
    }

    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
      message=("A new RouterOS version " . ($Update->"latest-version") . \
        " is available for " . $Identity . ".\n\n" . \
        [ $DeviceInfo ]); link=$Link; silent=true });
    :set SentRouterosUpdateNotification ($Update->"latest-version");
  }

  :if ($NumInstalled > $NumLatest) do={
    :if ($SentRouterosUpdateNotification = $Update->"latest-version") do={
      $LogPrint info $ScriptName ("Already sent the RouterOS downgrade notification for version " . \
          $Update->"latest-version" . ".");
      :set ExitOK true;
      :error true;
    }

    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "warning-sign" ] . "RouterOS version: " . $Update->"latest-version"); \
      message=("A different RouterOS version " . ($Update->"latest-version") . \
        " is available for " . $Identity . ", but it is a downgrade.\n\n" . \
        [ $DeviceInfo ]); link=$Link; silent=true });
    $LogPrint info $ScriptName ("A different RouterOS version " . ($Update->"latest-version") . \
      " is available for downgrade.");
    :set SentRouterosUpdateNotification ($Update->"latest-version");
  }
} on-error={
  :global ExitError; $ExitError $ExitOK [ :jobname ];
}
