#!rsc by RouterOS
# RouterOS script: backup-cloud
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: backup-script, order=40
# requires RouterOS, version=7.22
#
# upload backup to MikroTik cloud
# https://rsc.eworm.de/doc/backup-cloud.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=backup-cloud, schema=1d68cb944d178c8731db42b15cc1dc9e76c76322543a57e366c56830ef3b644d
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"backup-cloud.directory") "Failed creating directory!";
:set ($LanguageEnglish->"backup-cloud.label.key") "Download key";
:set ($LanguageEnglish->"backup-cloud.label.name") "Name";
:set ($LanguageEnglish->"backup-cloud.label.size") "Size";
:set ($LanguageEnglish->"backup-cloud.message") "Uploaded backup for {identity} to cloud.\0A\0A{device}\0A\0A{details}";
:set ($LanguageEnglish->"backup-cloud.message.failed") "Failed uploading backup for {identity} to cloud!\0A\0A{device}";
:set ($LanguageEnglish->"backup-cloud.partition") "Running from backup partition, refusing to act.";
:set ($LanguageEnglish->"backup-cloud.retry") "Retry successful, please discard previous connection errors.";
:set ($LanguageEnglish->"backup-cloud.subject") "Cloud backup";
:set ($LanguageEnglish->"backup-cloud.subject.failed") "Cloud backup failed";
:set ($LanguageEnglish->"backup-cloud.upload.failed") "Failed uploading backup for {identity} to cloud!";
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

  :global BackupRandomDelay;
  :global Identity;
  :global PackagesUpdateBackupFailure;

  :global DeviceInfo;
  :global FormatLine;
  :global HumanReadableNum;
  :global Translate;
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
    :exit;
  }

  :if ([ :len [ /system/scheduler/find where name="running-from-backup-partition" ] ] > 0) do={
    $LogPrint warning $ScriptName ([ $Translate "backup-cloud.partition" ]);
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  $WaitFullyConnected;

  :if ([ $ScriptFromTerminal $ScriptName ] = false && $BackupRandomDelay > 0) do={
    $RandomDelay $BackupRandomDelay;
  }

  :if ([ $MkDir ("tmpfs/backup-cloud") ] = false) do={
    $LogPrint error $ScriptName ([ $Translate "backup-cloud.directory" ]);
    :exit;
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
      :log warning ($ScriptName . ": " . [ $Translate "backup-cloud.retry" ]);
    }

    :local Cloud [ /system/backup/cloud/get ([ find ]->0) ];

    $SendNotification2 ({ origin=$ScriptName;  silent=true; \
      subject=([ $SymbolForNotification "floppy-disk,cloud" ] . [ $Translate "backup-cloud.subject" ]); \
      message=([ $Translate "backup-cloud.message" ({ identity=$Identity; device=[ $DeviceInfo ]; details=([ $FormatLine [ $Translate "backup-cloud.label.name" ] ($Cloud->"name") ] . "\n" . \
        [ $FormatLine [ $Translate "backup-cloud.label.size" ] ([ $HumanReadableNum ($Cloud->"size") 1024 ] . "B") ] . "\n" . \
        [ $FormatLine [ $Translate "backup-cloud.label.key" ] ($Cloud->"secret-download-key") ]) }) ]) });
  } else={
    $SendNotification2 ({ origin=$ScriptName;  silent=false; \
      subject=([ $SymbolForNotification "floppy-disk,warning-sign" ] . [ $Translate "backup-cloud.subject.failed" ]); \
      message=([ $Translate "backup-cloud.message.failed" ({ identity=$Identity; device=[ $DeviceInfo ] }) ]) });
    $LogPrint error $ScriptName ([ $Translate "backup-cloud.upload.failed" ({ identity=$Identity }) ]);
    :set PackagesUpdateBackupFailure true;
  }
  $RmDir "tmpfs/backup-cloud";
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
