#!rsc by RouterOS
# RouterOS script: backup-upload
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: backup-script
#
# create and upload backup and config file
# https://git.eworm.de/cgit/routeros-scripts/about/doc/backup-upload.md

:local 0 "backup-upload";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

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

:global CharacterReplace;
:global DeviceInfo;
:global FormatLine;
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
  $LogPrintExit2 error $0 ("Configured to send neither backup nor config export.") true;
}

$ScriptLock $0;
$WaitFullyConnected;

:if ([ $ScriptFromTerminal $0 ] = false && $BackupRandomDelay > 0) do={
  $RandomDelay $BackupRandomDelay;
}

# filename based on identity
:local DirName ("tmpfs/" . $0);
:local FileName [ $CharacterReplace ($Identity . "." . $Domain) "." "_" ];
:local FilePath ($DirName . "/" . $FileName);
:local BackupFile "none";
:local ExportFile "none";
:local ConfigFile "none";
:local Failed 0;

:if ([ $MkDir $DirName ] = false) do={
  $LogPrintExit2 error $0 ("Failed creating directory!") true;
}

# binary backup
:if ($BackupSendBinary = true) do={
  /system/backup/save encryption=aes-sha256 name=$FilePath password=$BackupPassword;
  $WaitForFile ($FilePath . ".backup");

  :do {
    /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".backup") \
        user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".backup");
    :set BackupFile ($FileName . ".backup");
  } on-error={
    $LogPrintExit2 error $0 ("Uploading backup file failed!") false;
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
    :set ExportFile ($FileName . ".rsc");
  } on-error={
    $LogPrintExit2 error $0 ("Uploading configuration export failed!") false;
    :set ExportFile "failed";
    :set Failed 1;
  }

  /file/remove ($FilePath . ".rsc");
}

# global-config-overlay
:if ($BackupSendGlobalConfig = true) do={
  :local Config [ /system/script/get global-config-overlay source ];
  /file/add name=($FilePath . ".conf") contents=$Config;
  $WaitForFile ($FilePath . ".conf");

  :do {
    /tool/fetch upload=yes url=($BackupUploadUrl . "/" . $FileName . ".conf") \
        user=$BackupUploadUser password=$BackupUploadPass src-path=($FilePath . ".conf");
    :set ConfigFile ($FileName . ".conf");
  } on-error={
    $LogPrintExit2 error $0 ("Uploading global-config-overlay failed!") false;
    :set ConfigFile "failed";
    :set Failed 1;
  }

  /file/remove ($FilePath . ".conf");
}

$SendNotification2 ({ origin=$0; \
  subject=[ $IfThenElse ($Failed > 0) \
    ([ $SymbolForNotification "floppy-disk,warning-sign" ] . "Backup & Config upload with failure") \
    ([ $SymbolForNotification "floppy-disk,up-arrow" ] . "Backup & Config upload") ]; \
  message=("Backup and config export upload for " . $Identity . ".\n\n" . \
    [ $DeviceInfo ] . "\n\n" . \
    [ $FormatLine "Backup file" $BackupFile ] . "\n" . \
    [ $FormatLine "Export file" $ExportFile ] . "\n" . \
    [ $FormatLine "Config file" $ConfigFile ]); silent=true });

:if ($Failed = 1) do={
  :error "An error occured!";
}
