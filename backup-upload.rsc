#!rsc by RouterOS
# RouterOS script: backup-upload
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: backup-script, order=50
# requires RouterOS, version=7.15
# requires device-mode, fetch
#
# create and upload backup and config file
# https://rsc.eworm.de/doc/backup-upload.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

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
    $LogPrint error $ScriptName ("Configured to send neither backup nor config export.");
    :set ExitOK true;
    :error false;
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

  $WaitFullyConnected;

  :if ([ $ScriptFromTerminal $ScriptName ] = false && $BackupRandomDelay > 0) do={
    $RandomDelay $BackupRandomDelay;
  }

  # filename based on identity
  :local DirName ("tmpfs/" . $ScriptName);
  :local FileName [ $CleanName ($Identity . "." . $Domain) ];
  :local FilePath ($DirName . "/" . $FileName);
  :local BackupFile "none";
  :local ExportFile "none";
  :local ConfigFile "none";
  :local Failed 0;

  :if ([ $MkDir $DirName ] = false) do={
    $LogPrint error $ScriptName ("Failed creating directory!");
    :set ExitOK true;
    :error false;
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
      $LogPrint error $ScriptName ("Uploading backup file failed: " . $Err);
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
      $LogPrint error $ScriptName ("Uploading configuration export failed: " . $Err);
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
      $LogPrint error $ScriptName ("Uploading global-config-overlay failed: " . $Err);
      :set ConfigFile "failed";
      :set Failed 1;
    }

    $RmFile ($FilePath . ".conf");
  }

  :local FileInfo do={
    :local Name $1;
    :local File $2;

    :global FormatLine;
    :global HumanReadableNum;
    :global IfThenElse;

    :return \
      [ $IfThenElse ([ :typeof $File ] = "array") \
        ($Name . ":\n" . [ $FormatLine "    name" ($File->"name") ] . "\n" . \
          [ $FormatLine "    size" ([ $HumanReadableNum ($File->"size") 1024 ] . "B") ]) \
        [ $FormatLine $Name $File ] ];
  }

  $SendNotification2 ({ origin=$ScriptName; \
    subject=[ $IfThenElse ($Failed > 0) \
      ([ $SymbolForNotification "floppy-disk,warning-sign" ] . "Backup & Config upload with failure") \
      ([ $SymbolForNotification "floppy-disk,arrow-up" ] . "Backup & Config upload") ]; \
    message=("Backup and config export upload for " . $Identity . ".\n\n" . \
      [ $DeviceInfo ] . "\n\n" . \
      [ $FileInfo "Backup file" $BackupFile ] . "\n" . \
      [ $FileInfo "Export file" $ExportFile ] . "\n" . \
      [ $FileInfo "Config file" $ConfigFile ]); silent=true });

  :if ($Failed = 1) do={
    :set PackagesUpdateBackupFailure true;
  }
  $RmDir $DirName;
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
