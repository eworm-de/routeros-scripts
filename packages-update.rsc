#!rsc by RouterOS
# RouterOS script: packages-update
# Copyright (c) 2019-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, scheduler
#
# download packages and reboot for installation
# https://rsc.eworm.de/doc/packages-update.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global BackupRandomDelay;
  :global PackagesUpdateDeferReboot;
  :global PackagesUpdateBackupFailure;

  :global DownloadPackage;
  :global Grep;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global VersionToNum;

  :local Schedule do={
    :local ScriptName [ :tostr $1 ];

    :global PackagesUpdateDeferReboot;

    :global GetRandomNumber;
    :global IfThenElse;
    :global LogPrint;

    :global RebootForUpdate do={
      /system/reboot;
    }

    :local Interval [ $IfThenElse ($PackagesUpdateDeferReboot >= 1d) $PackagesUpdateDeferReboot 1d ];
    :local StartTime [ :tostr [ :totime (10800 + [ $GetRandomNumber 7200 ]) ] ];
    /system/scheduler/add name="_RebootForUpdate" start-time=$StartTime interval=$Interval \
        on-event=("/system/scheduler/remove \"_RebootForUpdate\"; " . \
        ":global RebootForUpdate; \$RebootForUpdate;");
    $LogPrint info $ScriptName ("Scheduled reboot for update at " . $StartTime . \
        " local time (" . [ /system/clock/get time-zone-name ] . ")" . \
        [ $IfThenElse ($Interval > 1d) (" deferred by " . $Interval) ] . ".");
    :return true;
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

  :local Update [ /system/package/update/get ];

  :if ([ :typeof ($Update->"latest-version") ] = "nothing") do={
    $LogPrint warning $ScriptName ("Latest version is not known.");
    :set ExitOK true;
    :error false;
  }

  :if ($Update->"installed-version" = $Update->"latest-version") do={
    $LogPrint info $ScriptName ("Version " . $Update->"latest-version" . " is already installed.");
    :set ExitOK true;
    :error true;
  }

  :local RunOrder ({});
  :foreach Script in=[ /system/script/find where source~("\n# provides: backup-script\\b") ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local Store [ $ParseKeyValueStore [ $Grep ($ScriptVal->"source") ("\23 provides: backup-script, ") ] ];

    :set ($RunOrder->($Store->"order" . "-" . $ScriptVal->"name")) ($ScriptVal->"name");
  }

  :local BackupRandomDelayBefore $BackupRandomDelay;
  :foreach Order,Script in=$RunOrder do={
    :set BackupRandomDelay 0;
    :set PackagesUpdateBackupFailure false;
    :do {
      $LogPrint info $ScriptName ("Running backup script " . $Script . " before update.");
      /system/script/run $Script;
    } on-error={
      :set PackagesUpdateBackupFailure true;
    }
    :set BackupRandomDelay $BackupRandomDelayBefore;

    :if ($PackagesUpdateBackupFailure = true) do={
      $LogPrint warning $ScriptName ("Running backup script " . $Script . " before update failed!");
      :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
        :put "Do you want to continue anyway? [y/N]";
        :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          $LogPrint info $ScriptName ("User requested to continue anyway.");
        } else={
          $LogPrint info $ScriptName ("Canceled update...");
          :set ExitOK true;
          :error false;
        }
      } else={
        $LogPrint warning $ScriptName ("Canceled non-interactive update.");
        :set ExitOK true;
        :error false;
      }
    }
  }

  :local NumInstalled [ $VersionToNum ($Update->"installed-version") ];
  :local NumLatest [ $VersionToNum ($Update->"latest-version") ];

  :local DoDowngrade false;
  :if ($NumInstalled > $NumLatest) do={
    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      :put "Latest version is older than installed one. Want to downgrade? [y/N]";
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
        :set DoDowngrade true;
      } else={
        :put "Canceled...";
      }
    } else={
      $LogPrint warning $ScriptName ("Not installing downgrade automatically.");
      :set ExitOK true;
      :error false;
    }
  }

  :foreach Package in=[ /system/package/find where !bundle !available ] do={
    :local PkgName [ /system/package/get $Package name ];
    :if ([ $DownloadPackage $PkgName ($Update->"latest-version") ] = false) do={
      $LogPrint error $ScriptName ("Download for package " . $PkgName . " failed, update aborted.");
      :set ExitOK true;
      :error false;
    }
  }

  :if ($DoDowngrade = true) do={
    $LogPrint info $ScriptName ("Rebooting for downgrade.");
    :delay 1s;
    /system/package/downgrade;
  }

  :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
    :put "Do you want to (s)chedule reboot or (r)eboot now? [s/R]";
    :if (([ /terminal/inkey timeout=60 ] % 32) = 19) do={
      $Schedule $ScriptName;
      :set ExitOK true;
      :error true;
    }
  } else={
    :if ($PackagesUpdateDeferReboot = true || $PackagesUpdateDeferReboot >= 1d) do={
      $Schedule $ScriptName;
      :set ExitOK true;
      :error true;
    }
  }

  $LogPrint info $ScriptName ("Rebooting for update.");
  :delay 1s;
  /system/reboot;
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
