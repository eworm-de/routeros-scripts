#!rsc by RouterOS
# RouterOS script: packages-update
# Copyright (c) 2019-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.13
#
# download packages and reboot for installation
# https://git.eworm.de/cgit/routeros-scripts/about/doc/packages-update.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global DownloadPackage;
  :global Grep;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global VersionToNum;

  :global PackagesUpdateDeferReboot;
  :global PackagesUpdateBackupFailure;

  :local Schedule do={
    :local ScriptName [ :tostr $1 ];

    :global GetRandomNumber;
    :global LogPrint;

    :global RebootForUpdate do={
      /system/reboot;
    }

    :local StartTime [ :tostr [ :totime (10800 + [ $GetRandomNumber 7200 ]) ] ];
    /system/scheduler/add name="_RebootForUpdate" start-time=$StartTime interval=1d \
        on-event=("/system/scheduler/remove \"_RebootForUpdate\"; " . \
        ":global RebootForUpdate; \$RebootForUpdate;");
    $LogPrint info $ScriptName ("Scheduled reboot for update at " . $StartTime . \
        " local time (" . [ /system/clock/get time-zone-name ] . ").");
    :return true;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :error false;
  }

  :local Update [ /system/package/update/get ];

  :if ([ :typeof ($Update->"latest-version") ] = "nothing") do={
    $LogPrint warning $ScriptName ("Latest version is not known.");
    :error false;
  }

  :if ($Update->"installed-version" = $Update->"latest-version") do={
    $LogPrint info $ScriptName ("Version " . $Update->"latest-version" . " is already installed.");
    :error true;
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
      :error false;
    }
  }

  :foreach Package in=[ /system/package/find where !bundle ] do={
    :local PkgName [ /system/package/get $Package name ];
    :if ([ $DownloadPackage $PkgName ($Update->"latest-version") ] = false) do={
      $LogPrint error $ScriptName ("Download for package " . $PkgName . " failed, update aborted.");
      :error false;
    }
  }

  :local RunOrder ({});
  :foreach Script in=[ /system/script/find where source~("\n# provides: backup-script\\b") ] do={
    :local ScriptVal [ /system/script/get $Script ];
    :local Store [ $ParseKeyValueStore [ $Grep ($ScriptVal->"source") ("\23 provides: backup-script, ") ] ];

    :set ($RunOrder->($Store->"order" . "-" . $ScriptVal->"name")) ($ScriptVal->"name");
  }

  :foreach Order,Script in=$RunOrder do={
    :set PackagesUpdateBackupFailure false;
    :do {
      $LogPrint info $ScriptName ("Running backup script " . $Script . " before update.");
      /system/script/run $Script;
    } on-error={
      :set PackagesUpdateBackupFailure true;
    }

    :if ($PackagesUpdateBackupFailure = true) do={
      $LogPrint warning $ScriptName ("Running backup script " . $Script . " before update failed!");
      :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
        :put "Do you want to continue anyway? [y/N]";
        :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          $LogPrint info $ScriptName ("User requested to continue anyway.");
        } else={
          $LogPrint info $ScriptName ("Canceled update...");
          :error false;
        }
      } else={
        $LogPrint warning $ScriptName ("Canceled non-interactive update.");
        :error false;
      }
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
    }
  } else={
    :if ($PackagesUpdateDeferReboot = true) do={
      $Schedule $ScriptName;
    }
  }

  $LogPrint info $ScriptName ("Rebooting for update.");
  :delay 1s;
  /system/reboot;
} on-error={ }
