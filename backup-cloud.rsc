#!rsc by RouterOS
# Skrip RouterOS: backup-cloud
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: backup-script, order=40
# requires RouterOS, version=7.15
#
# upload backup to MikroTik cloud
# https://rsc.eworm.de/doc/backup-cloud.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global BackupRandomDelay;
  :global Identity;
  :global PackagesUpdateBackupFailure;

  :global DeviceInfo;
  :global FormatLine;
  :global HumanReadableNum;
  :global LogPrint;
  :global MkDir;
  :global RandomDelay;
  :global RmDir;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global WaitForFile;
  :global WaitFullyConnected;

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

  $WaitFullyConnected;

  :if ([ $ScriptFromTerminal $ScriptName ] = false && $BackupRandomDelay > 0) do={
    $RandomDelay $BackupRandomDelay;
  }

  :if ([ $MkDir ("tmpfs/backup-cloud") ] = false) do={
    $LogPrint error $ScriptName ("Failed creating directory!");
    :set ExitOK true;
    :error false;
  }

  :local I 5;
  :do {
    :execute {
      :global BackupPassword;

      :local Backup ([ /system/backup/cloud/find ]->0);
      :if ([ :typeof $Backup ] = "id") do={
        /system/backup/cloud/upload-file action=create-and-upload \
            password=$BackupPassword replace=$Backup;
      } else={
        /system/backup/cloud/upload-file action=create-and-upload \
            password=$BackupPassword;
      }
      /file/add name="tmpfs/backup-cloud/done";
    } as-string;
    :set I ($I - 1);
  } while=([ $WaitForFile "tmpfs/backup-cloud/done" 200ms ] = false && $I > 0);

  :if ([ $WaitForFile "tmpfs/backup-cloud/done" ] = true) do={
    :if ($I < 4) do={
      :log warning ($ScriptName . ": Retry successful, please discard previous connection errors.");
    }

    :local Cloud [ /system/backup/cloud/get ([ find ]->0) ];

    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "floppy-disk,cloud" ] . "Cloud backup"); \
      message=("Uploaded backup for " . $Identity . " to cloud.\n\n" . \
        [ $DeviceInfo ] . "\n\n" . \
        [ $FormatLine "Name" ($Cloud->"name") ] . "\n" . \
        [ $FormatLine "Size" ([ $HumanReadableNum ($Cloud->"size") 1024 ] . "B") ] . "\n" . \
        [ $FormatLine "Download key" ($Cloud->"secret-download-key") ]); silent=true });
  } else={
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "floppy-disk,warning-sign" ] . "Cloud backup failed"); \
      message=("Failed uploading backup for " . $Identity . " to cloud!\n\n" . [ $DeviceInfo ]) });
    $LogPrint error $ScriptName ("Failed uploading backup for " . $Identity . " to cloud!");
    :set PackagesUpdateBackupFailure true;
  }
  $RmDir "tmpfs/backup-cloud";
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
