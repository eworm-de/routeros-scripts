#!rsc by RouterOS
# RouterOS script: backup-upload
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: backup-script, order=50
# requires RouterOS, version=7.22
# requires device-mode, fetch
#
# create and upload backup and config file
# https://rsc.eworm.de/doc/backup-upload.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=backup-upload, schema=ac3b0aa1324d76ce3ef1515ba46a556bd27200aeea4ad75af6d1e26fd41bf67d
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"backup-upload.directory") "Failed creating directory!";
:set ($LanguageEnglish->"backup-upload.failed") "failed";
:set ($LanguageEnglish->"backup-upload.label.backup") "Backup file";
:set ($LanguageEnglish->"backup-upload.label.config") "Config file";
:set ($LanguageEnglish->"backup-upload.label.export") "Export file";
:set ($LanguageEnglish->"backup-upload.label.name") "    name";
:set ($LanguageEnglish->"backup-upload.label.size") "    size";
:set ($LanguageEnglish->"backup-upload.message") "Backup and config export upload for {identity}.\0A\0A{device}\0A\0A{details}";
:set ($LanguageEnglish->"backup-upload.none") "none";
:set ($LanguageEnglish->"backup-upload.options") "Configured to send neither backup nor config export.";
:set ($LanguageEnglish->"backup-upload.partition") "Running from backup partition, refusing to act.";
:set ($LanguageEnglish->"backup-upload.subject") "Backup & Config upload";
:set ($LanguageEnglish->"backup-upload.subject.failed") "Backup & Config upload with failure";
:set ($LanguageEnglish->"backup-upload.upload.backup.failed") "Uploading backup file failed: {error}";
:set ($LanguageEnglish->"backup-upload.upload.config.failed") "Uploading global-config-overlay failed: {error}";
:set ($LanguageEnglish->"backup-upload.upload.export.failed") "Uploading configuration export failed: {error}";
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

  :global BackupFileNameDate;
  :global BackupPassword;
  :global BackupRandomDelay;
  :global BackupSendBinary;
  :global BackupSendExport;
  :global BackupSendGlobalConfig;
  :global BackupUploadPass;
  :global BackupUploadUrl;
  :global BackupUploadUser;
  :global Domain;
  :global Identity;
  :global PackagesUpdateBackupFailure;

  :global CleanName;
  :global DeviceInfo;
  :global IfThenElse;
  :global Translate;
  :global LogPrint;
  :global MkDir;
  :global RandomDelay;
  :global RmDir;
  :global RmFile;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global WaitForFile;
  :global WaitFullyConnected;

  :if ($BackupSendBinary != true && \
       $BackupSendExport != true) do={
    $LogPrint error $ScriptName ([ $Translate "backup-upload.options" ]);
    :exit;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  :if ([ :len [ /system/scheduler/find where name="running-from-backup-partition" ] ] > 0) do={
    $LogPrint warning $ScriptName ([ $Translate "backup-upload.partition" ]);
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  $WaitFullyConnected;

  :if ([ $ScriptFromTerminal $ScriptName ] = false && $BackupRandomDelay > 0) do={
    $RandomDelay $BackupRandomDelay;
  }

  # filename based on identity
  :local DirName ("tmpfs/" . $ScriptName);
  :local Clock [ /system/clock/get ];
  :local FileName [ $CleanName ($Identity . "." . $Domain . [ $IfThenElse \
      ($BackupFileNameDate = true) ("-" . $Clock->"date" . "-" . $Clock->"time") "" ] ) ];
  :local FilePath ($DirName . "/" . $FileName);
  :local BackupFile "none";
  :local ExportFile "none";
  :local ConfigFile "none";
  :local Failed 0;

  :if ([ $MkDir $DirName ] = false) do={
    $LogPrint error $ScriptName ([ $Translate "backup-upload.directory" ]);
    :exit;
  }

  # binary backup
  :if ($BackupSendBinary = true) do={
    /system/backup/save encryption=aes-sha256 name=$FilePath password=$BackupPassword;
    $WaitForFile ($FilePath . ".backup");

    :onerror Err {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".backup") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".backup");
      :set BackupFile [ /file/get ($FilePath . ".backup") ];
      :set ($BackupFile->"name") ($FileName . ".backup");
    } do={
      $LogPrint error $ScriptName ([ $Translate "backup-upload.upload.backup.failed" ({ error=$Err }) ]);
      :set BackupFile "failed";
      :set Failed 1;
    }

    $RmFile ($FilePath . ".backup");
  }

  # create configuration export
  :if ($BackupSendExport = true) do={
    /export terse show-sensitive file=$FilePath;
    $WaitForFile ($FilePath . ".rsc");

    :onerror Err {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".rsc") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".rsc");
      :set ExportFile [ /file/get ($FilePath . ".rsc") ];
      :set ($ExportFile->"name") ($FileName . ".rsc");
    } do={
      $LogPrint error $ScriptName ([ $Translate "backup-upload.upload.export.failed" ({ error=$Err }) ]);
      :set ExportFile "failed";
      :set Failed 1;
    }

    $RmFile ($FilePath . ".rsc");
  }

  # global-config-overlay
  :if ($BackupSendGlobalConfig = true) do={
    # Do *NOT* use '/file/add ...' here, as it is limited to 4095 bytes!
    :execute script={ :put [ /system/script/get global-config-overlay source ]; } \
        file=($FilePath . ".conf\00");
    $WaitForFile ($FilePath . ".conf");

    :onerror Err {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".conf") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".conf");
      :set ConfigFile [ /file/get ($FilePath . ".conf") ];
      :set ($ConfigFile->"name") ($FileName . ".conf");
    } do={
      $LogPrint error $ScriptName ([ $Translate "backup-upload.upload.config.failed" ({ error=$Err }) ]);
      :set ConfigFile "failed";
      :set Failed 1;
    }

    $RmFile ($FilePath . ".conf");
  }

  :local FileInfo do={
    :local Name $1;
    :local File $2;

    :global Translate;
    :global FormatLine;
    :global HumanReadableNum;
    :global IfThenElse;

    :return \
      [ $IfThenElse ([ :typeof $File ] = "array") \
        ($Name . ":\n" . [ $FormatLine [ $Translate "backup-upload.label.name" ] ($File->"name") ] . "\n" . \
          [ $FormatLine [ $Translate "backup-upload.label.size" ] ([ $HumanReadableNum ($File->"size") 1024 ] . "B") ]) \
        [ $FormatLine $Name [ $IfThenElse ($File = "none") [ $Translate "backup-upload.none" ] [ $IfThenElse ($File = "failed") [ $Translate "backup-upload.failed" ] $File ] ] ] ];
  }

  $SendNotification2 ({ origin=$ScriptName; \
    subject=[ $IfThenElse ($Failed > 0) \
      ([ $SymbolForNotification "floppy-disk,warning-sign" ] . [ $Translate "backup-upload.subject.failed" ]) \
      ([ $SymbolForNotification "floppy-disk,arrow-up" ] . [ $Translate "backup-upload.subject" ]) ]; \
    message=([ $Translate "backup-upload.message" ({ identity=$Identity; device=[ $DeviceInfo ]; details=([ $FileInfo [ $Translate "backup-upload.label.backup" ] $BackupFile ] . "\n" . \
      [ $FileInfo [ $Translate "backup-upload.label.export" ] $ExportFile ] . "\n" . \
      [ $FileInfo [ $Translate "backup-upload.label.config" ] $ConfigFile ]) }) ]); silent=true });

  :if ($Failed = 1) do={
    :set PackagesUpdateBackupFailure true;
  }
  $RmDir $DirName;
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
