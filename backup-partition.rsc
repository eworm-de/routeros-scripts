#!rsc by RouterOS
# RouterOS script: backup-partition
# Copyright (c) 2022-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: backup-script, order=70
# requires RouterOS, version=7.13
#
# save configuration to fallback partition
# https://git.eworm.de/cgit/routeros-scripts/about/doc/backup-partition.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
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

    :do {
      /partitions/copy-to $FallbackTo;
      $LogPrint info $ScriptName ("Copied RouterOS to partition '" . $FallbackToName . "'.");
      :return true;
    } on-error={
      $LogPrint error $ScriptName ("Failed copying RouterOS to partition '" . $FallbackToName . "'!");
      :return false;
    }
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set PackagesUpdateBackupFailure true;
    :error false;
  }

  :if ([ :len [ /partitions/find ] ] < 2) do={
    $LogPrint error $ScriptName ("Device does not have a fallback partition.");
    :set PackagesUpdateBackupFailure true;
    :error false;
  }

  :local ActiveRunning [ /partitions/find where active running ];

  :if ([ :len $ActiveRunning ] < 1) do={
    $LogPrint error $ScriptName ("Device is not running from active partition.");
    :set PackagesUpdateBackupFailure true;
    :error false;
  }

  :local FallbackToName [ /partitions/get $ActiveRunning fallback-to ];
  :local FallbackTo [ /partition/find where name=$FallbackToName ];

  :if ([ :len $FallbackTo ] < 1) do={
    $LogPrint error $ScriptName ("There is no partition with name '" . $FallbackToName . "'.");
    :set PackagesUpdateBackupFailure true;
    :error false;
  }

  :if ([ /partitions/get $ActiveRunning version ] != [ /partitions/get $FallbackTo version]) do={
    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      :put ("The partitions have different RouterOS versions. Copy over to '" . $FallbackToName . "'? [y/N]");
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
        :if ([ $CopyTo $ScriptName $FallbackTo $FallbackToName ] = false) do={
          :set PackagesUpdateBackupFailure true;
          :error false;
        }
      }
    } else={
      :local Update [ /system/package/update/get ];
      :local NumInstalled [ $VersionToNum ($Update->"installed-version") ];
      :local NumLatest [ $VersionToNum ($Update->"latest-version") ];
      :if ($BackupPartitionCopyBeforeFeatureUpdate = true && $NumLatest > 0 && \
           ($NumInstalled & 0xffff0000) != ($NumLatest & 0xffff0000)) do={
        :if ([ $CopyTo $ScriptName $FallbackTo $FallbackToName ] = false) do={
          :set PackagesUpdateBackupFailure true;
          :error false;
        }
      }
    }
  }

  :do {
    /system/scheduler/add start-time=startup name="running-from-backup-partition" \
        on-event=(":log warning (\"Running from partition '\" . " . \
        "[ /partitions/get [ find where running ] name ] . \"'!\")");
    /partitions/save-config-to $FallbackTo;
    /system/scheduler/remove "running-from-backup-partition";
    $LogPrint info $ScriptName ("Saved configuration to partition '" . $FallbackToName . "'.");
  } on-error={
    /system/scheduler/remove [ find where name="running-from-backup-partition" ];
    $LogPrint error $ScriptName ("Failed saving configuration to partition '" . $FallbackToName . "'!");
    :set PackagesUpdateBackupFailure true;
    :error false;
  }
} on-error={ }
