#!rsc by RouterOS
# RouterOS script: backup-partition
# Copyright (c) 2022-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: backup-script, order=70
# requires RouterOS, version=7.17
# requires device-mode, scheduler
#
# save configuration to fallback partition
# https://rsc.eworm.de/doc/backup-partition.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global BackupPartitionCopyBeforeFeatureUpdate;
  :global PackagesUpdateBackupFailure;

  :global LogPrint;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global VersionToNum;

  :local CopyTo do={
    :local ScriptName     [ :tostr $1 ];
    :local FallbackTo     [ :toid  $2 ];
    :local FallbackToName [ :tostr $3 ];

    :global LogPrint;

    :onerror Err {
      /partitions/copy-to $FallbackTo;
      $LogPrint info $ScriptName ("Copied RouterOS to partition '" . $FallbackToName . "'.");
    } do={
      $LogPrint error $ScriptName ("Failed copying RouterOS to partition '" . \
          $FallbackToName . "': " . $Err);
      :return false;
    }
    :return true;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set PackagesUpdateBackupFailure true;
    :set ExitOK true;
    :error false;
  }

  :if ([ :len [ /system/scheduler/find where name="running-from-backup-partition" ] ] > 0) do={
    $LogPrint warning $ScriptName ("Running from backup partition, refusing to act.");
    :set PackagesUpdateBackupFailure true;
    :set ExitOK true;
    :error false;
  }

  :if ([ :len [ /partitions/find ] ] < 2) do={
    $LogPrint error $ScriptName ("Device does not have a fallback partition.");
    :set PackagesUpdateBackupFailure true;
    :set ExitOK true;
    :error false;
  }

  :local ActiveRunning [ /partitions/find where active running ];

  :if ([ :len $ActiveRunning ] < 1) do={
    $LogPrint error $ScriptName ("Device is not running from active partition.");
    :set PackagesUpdateBackupFailure true;
    :set ExitOK true;
    :error false;
  }

  :local FallbackToName [ /partitions/get $ActiveRunning fallback-to ];
  :local FallbackTo [ /partition/find where name=$FallbackToName !active ];

  :if ([ :len $FallbackTo ] < 1) do={
    $LogPrint error $ScriptName ("There is no inactive partition named '" . $FallbackToName . "'.");
    :set PackagesUpdateBackupFailure true;
    :set ExitOK true;
    :error false;
  }

  :if ([ /partitions/get $ActiveRunning version ] != [ /partitions/get $FallbackTo version]) do={
    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      :put ("The partitions have different RouterOS versions. Copy over to '" . $FallbackToName . "'? [y/N]");
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
        :if ([ $CopyTo $ScriptName $FallbackTo $FallbackToName ] = false) do={
          :set PackagesUpdateBackupFailure true;
          :set ExitOK true;
          :error false;
        }
      }
    } else={
      :local Update [ /system/package/update/get ];
      :local NumInstalled [ $VersionToNum ($Update->"installed-version") ];
      :local NumLatest [ $VersionToNum ($Update->"latest-version") ];
      :local BitMask [ $VersionToNum "255.255zero0" ];
      :if ($BackupPartitionCopyBeforeFeatureUpdate = true && $NumLatest > 0 && \
           ($NumInstalled & $BitMask) != ($NumLatest & $BitMask)) do={
        :if ([ $CopyTo $ScriptName $FallbackTo $FallbackToName ] = false) do={
          :set PackagesUpdateBackupFailure true;
          :set ExitOK true;
          :error false;
        }
      }
    }
  }

  :onerror Err {
    /system/scheduler/add start-time=startup name="running-from-backup-partition" \
        on-event=(":log warning (\"Running from partition '\" . " . \
        "[ /partitions/get [ find where running ] name ] . \"'!\")");
    /partitions/save-config-to $FallbackTo;
    /system/scheduler/remove "running-from-backup-partition";
    $LogPrint info $ScriptName ("Saved configuration to partition '" . $FallbackToName . "'.");
  } do={
    /system/scheduler/remove [ find where name="running-from-backup-partition" ];
    $LogPrint error $ScriptName ("Failed saving configuration to partition '" . \
        $FallbackToName . "': " . $Err);
    :set PackagesUpdateBackupFailure true;
    :set ExitOK true;
    :error false;
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
