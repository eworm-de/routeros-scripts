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

  :global PackagesUpdateBackupFailure;

  :global LogPrint;
  :global ScriptFromTerminal;
  :global ScriptLock;

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

  :local FallbackTo [ /partitions/get $ActiveRunning fallback-to ];

  :if ([ /partitions/get $ActiveRunning version ] != [ /partitions/get $FallbackTo version]) do={
    :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
      :put ("The partitions have different RouterOS versions. Copy over to '" . $FallbackTo . "'? [y/N]");
      :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
        :do {
          /partitions/copy-to $FallbackTo;
          $LogPrint info $ScriptName ("Copied RouterOS to partition '" . $FallbackTo . "'.");
        } on-error={
          $LogPrint error $ScriptName ("Failed copying RouterOS to partition '" . $FallbackTo . "'!");
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
    $LogPrint info $ScriptName ("Saved configuration to partition '" . $FallbackTo . "'.");
  } on-error={
    /system/scheduler/remove [ find where name="running-from-backup-partition" ];
    $LogPrint error $ScriptName ("Failed saving configuration to partition '" . $FallbackTo . "'!");
    :set PackagesUpdateBackupFailure true;
    :error false;
  }
} on-error={ }
