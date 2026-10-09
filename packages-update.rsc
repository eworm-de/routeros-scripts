#!rsc by RouterOS
# RouterOS script: packages-update
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, scheduler
#
# download packages and reboot for installation
# https://rsc.eworm.de/doc/packages-update.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=packages-update, schema=77f3f83454477a8d375bfb399dd18ea210e50ceaf290213460a2f613ac47abd1
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"packages-update.backup.failed") "Running backup script {name} before update failed!";
:set ($LanguageEnglish->"packages-update.backup.partition") "Running from backup partition, refusing to act.";
:set ($LanguageEnglish->"packages-update.backup.running") "Running backup script {name} before update.";
:set ($LanguageEnglish->"packages-update.canceled") "Canceled...";
:set ($LanguageEnglish->"packages-update.canceled.noninteractive") "Canceled non-interactive update.";
:set ($LanguageEnglish->"packages-update.canceled.update") "Canceled update...";
:set ($LanguageEnglish->"packages-update.continue") "User requested to continue anyway.";
:set ($LanguageEnglish->"packages-update.continue.prompt") "Do you want to continue anyway? [y/N]";
:set ($LanguageEnglish->"packages-update.downgrade.prompt") "Latest version is older than installed one. Want to downgrade? [y/N]";
:set ($LanguageEnglish->"packages-update.downgrade.reboot") "Rebooting for downgrade.";
:set ($LanguageEnglish->"packages-update.downgrade.refused") "Not installing downgrade automatically.";
:set ($LanguageEnglish->"packages-update.download.failed") "Download for package {name} failed, update aborted.";
:set ($LanguageEnglish->"packages-update.license.expired") "The license expired, upgrade is blocked.";
:set ($LanguageEnglish->"packages-update.reboot.prompt") "Do you want to (s)chedule reboot or (r)eboot now? [s/R]";
:set ($LanguageEnglish->"packages-update.scheduled") "Scheduled reboot for update at {time} local time ({timezone}).";
:set ($LanguageEnglish->"packages-update.scheduled.deferred") "Scheduled reboot for update at {time} local time ({timezone}) deferred by {interval}.";
:set ($LanguageEnglish->"packages-update.scheduler.exists") "Scheduler for reboot already exists.";
:set ($LanguageEnglish->"packages-update.update.reboot") "Rebooting for update.";
:set ($LanguageEnglish->"packages-update.version.installed") "Version {version} is already installed.";
:set ($LanguageEnglish->"packages-update.version.unknown") "Latest version is not known.";
# END GENERATED LANGUAGE DATA

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
  :global Translate;
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
    :global Translate;

    :global RebootForUpdate do={
      /system/reboot;
    }

    :if ([ :len [ /system/scheduler/find where name="_RebootForUpdate" ] ] > 0) do={
      $LogPrint warning $ScriptName [ $Translate "packages-update.scheduler.exists" ];
      :return false;
    }

    :local Interval [ $IfThenElse ([ :totime $PackagesUpdateDeferReboot ] >= 1d) \
        $PackagesUpdateDeferReboot 1d ];
    :local StartTime [ :tostr [ :totime (10800 + [ $GetRandomNumber 7200 ]) ] ];
    /system/scheduler/add name="_RebootForUpdate" start-time=$StartTime interval=$Interval \
        on-event=("/system/scheduler/remove \"_RebootForUpdate\"; " . \
        ":global RebootForUpdate; \$RebootForUpdate;");
    :local Message [ $Translate "packages-update.scheduled" ({ time=$StartTime; \
        timezone=[ /system/clock/get time-zone-name ]; }) ];
    :if ($Interval > 1d) do={
      :set Message [ $Translate "packages-update.scheduled.deferred" ({ time=$StartTime; \
          timezone=[ /system/clock/get time-zone-name ]; interval=$Interval; }) ];
    }
    $LogPrint info $ScriptName $Message;
    :return true;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :if (([ /system/license/get ]->"limited-upgrades") = true) do={
    $LogPrint warning $ScriptName [ $Translate "packages-update.license.expired" ];
    :exit;
  }

  :if ([ :len [ /system/scheduler/find where name="running-from-backup-partition" ] ] > 0) do={
    $LogPrint warning $ScriptName [ $Translate "packages-update.backup.partition" ];
    :exit;
  }

  :local Update [ /system/package/update/get ];

  :if ([ :typeof ($Update->"latest-version") ] = "nothing") do={
    $LogPrint warning $ScriptName [ $Translate "packages-update.version.unknown" ];
    :exit;
  }

  :if ($Update->"installed-version" = $Update->"latest-version") do={
    $LogPrint info $ScriptName [ $Translate "packages-update.version.installed" \
        ({ version=($Update->"latest-version"); }) ];
    :exit;
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
      $LogPrint info $ScriptName [ $Translate "packages-update.backup.running" ({ name=$Script; }) ];
      /system/script/run $Script;
    } on-error={
      :set PackagesUpdateBackupFailure true;
    }
    :set BackupRandomDelay $BackupRandomDelayBefore;

    :if ($PackagesUpdateBackupFailure = true) do={
      $LogPrint warning $ScriptName [ $Translate "packages-update.backup.failed" ({ name=$Script; }) ];
      :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
        :put [ $Translate "packages-update.continue.prompt" ];
        :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          $LogPrint info $ScriptName [ $Translate "packages-update.continue" ];
        } else={
          $LogPrint info $ScriptName [ $Translate "packages-update.canceled.update" ];
          :exit;
        }
      } else={
        $LogPrint warning $ScriptName [ $Translate "packages-update.canceled.noninteractive" ];
        :exit;
      }
    }
  }

  :local NumInstalled [ $VersionToNum ($Update->"installed-version") ];
  :local NumLatest [ $VersionToNum ($Update->"latest-version") ];

  :local DoDowngrade false;
  :if ($NumInstalled > $NumLatest) do={
    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      :put [ $Translate "packages-update.downgrade.prompt" ];
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
        :set DoDowngrade true;
      } else={
        :put [ $Translate "packages-update.canceled" ];
      }
    } else={
      $LogPrint warning $ScriptName [ $Translate "packages-update.downgrade.refused" ];
      :exit;
    }
  }

  :foreach Package in=[ /system/package/find where !bundle !available ] do={
    :local PkgName [ /system/package/get $Package name ];
    :if ([ $DownloadPackage $PkgName ($Update->"latest-version") ] = false) do={
      $LogPrint error $ScriptName [ $Translate "packages-update.download.failed" ({ name=$PkgName; }) ];
      :exit;
    }
  }

  :if ($DoDowngrade = true) do={
    $LogPrint info $ScriptName [ $Translate "packages-update.downgrade.reboot" ];
    :delay 1s;
    /system/package/downgrade;
  }

  :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
    :put [ $Translate "packages-update.reboot.prompt" ];
    :if (([ /terminal/inkey timeout=60 ] % 32) = 19) do={
      $Schedule $ScriptName;
      :exit;
    }
  } else={
    :if ($PackagesUpdateDeferReboot = true || [ :totime $PackagesUpdateDeferReboot ] >= 1d) do={
      $Schedule $ScriptName;
      :exit;
    }
  }

  $LogPrint info $ScriptName [ $Translate "packages-update.update.reboot" ];
  :delay 1s;
  /system/reboot;
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
