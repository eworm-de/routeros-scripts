#!rsc by RouterOS
# RouterOS script: backup-upload
# Copyright (c) 2013-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: backup-script, order=50
# requires RouterOS, version=7.12
#
# create and upload backup and config file
# https://git.eworm.de/cgit/routeros-scripts/about/doc/backup-upload.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
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
  :global LogPrintExit2;
  :global MkDir;
  :global RandomDelay;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global WaitForFile;
  :global WaitFullyConnected;

  :if ($BackupSendBinary != true && \
       $BackupSendExport != true) do={
    $LogPrintExit2 error $ScriptName ("Configured to send neither backup nor config export.") true;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set PackagesUpdateBackupFailure true;
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
    $LogPrintExit2 error $ScriptName ("Failed creating directory!") true;
  }

  # binary backup
  :if ($BackupSendBinary = true) do={
    /system/backup/save encryption=aes-sha256 name=$FilePath password=$BackupPassword;
    $WaitForFile ($FilePath . ".backup");

    :do {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".backup") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".backup");
      :set BackupFile [ /file/get ($FilePath . ".backup") ];
      :set ($BackupFile->"name") ($FileName . ".backup");
    } on-error={
      $LogPrintExit2 error $ScriptName ("Uploading backup file failed!") false;
      :set BackupFile "failed";
      :set Failed 1;
    }

    /file/remove ($FilePath . ".backup");
  }

  # create configuration export
  :if ($BackupSendExport = true) do={
    /export terse show-sensitive file=$FilePath;
    $WaitForFile ($FilePath . ".rsc");

    :do {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".rsc") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".rsc");
      :set ExportFile [ /file/get ($FilePath . ".rsc") ];
      :set ($ExportFile->"name") ($FileName . ".rsc");
    } on-error={
      $LogPrintExit2 error $ScriptName ("Uploading configuration export failed!") false;
      :set ExportFile "failed";
      :set Failed 1;
    }

    /file/remove ($FilePath . ".rsc");
  }

  # global-config-overlay
  :if ($BackupSendGlobalConfig = true) do={
    # Do *NOT* use '/file/add ...' here, as it is limited to 4095 bytes!
    :execute script={ :put [ /system/script/get global-config-overlay source ]; } \
        file=($FilePath . ".conf\00");
    $WaitForFile ($FilePath . ".conf");

    :do {
      /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".conf") \
          user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".conf");
      :set ConfigFile [ /file/get ($FilePath . ".conf") ];
      :set ($ConfigFile->"name") ($FileName . ".conf");
    } on-error={
      $LogPrintExit2 error $ScriptName ("Uploading global-config-overlay failed!") false;
      :set ConfigFile "failed";
      :set Failed 1;
    }

    /file/remove ($FilePath . ".conf");
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
          [ $FormatLine "    size" ([ $HumanReadableNum ($File->"size") 1024 ] . "iB") ]) \
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
    :error false;
  }
} on-error={ }
