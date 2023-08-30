#!rsc by RouterOS
# RouterOS script: backup-email
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: backup-script
#
# create and email backup and config file
# https://git.eworm.de/cgit/routeros-scripts/about/doc/backup-email.md

:local 0 "backup-email";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global BackupPassword;
:global BackupRandomDelay;
:global BackupSendBinary;
:global BackupSendExport;
:global BackupSendGlobalConfig;
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
:global SendEMail2;
:global SymbolForNotification;
:global WaitForFile;
:global WaitFullyConnected;

:if ([ :typeof $SendEMail2 ] = "nothing") do={
  $LogPrintExit2 error $0 ("The module for sending notifications via e-mail is not installed.") true;
}

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
:local Attach ({});
:local Failed 0;

:if ([ $MkDir $DirName ] = false) do={
  $LogPrintExit2 error $0 ("Failed creating directory!") true;
}

# binary backup
:if ($BackupSendBinary = true) do={
  /system/backup/save encryption=aes-sha256 name=$FilePath password=$BackupPassword;
  $WaitForFile ($FilePath . ".backup");
  :set BackupFile ($FileName . ".backup");
  :set Attach ($Attach, ($FilePath . ".backup"));
}

# create configuration export
:if ($BackupSendExport = true) do={
  /export terse show-sensitive file=$FilePath;
  $WaitForFile ($FilePath . ".rsc");
  :set ExportFile ($FileName . ".rsc");
  :set Attach ($Attach, ($FilePath . ".rsc"));
}

# global-config-overlay
:if ($BackupSendGlobalConfig = true) do={
  :local Config [ /system/script/get global-config-overlay source ];
  :local Size [ :len $Config ];

  :if ($Size <= 4095) {
    /file/add name=($FilePath . ".conf") contents=$Config;
    $WaitForFile ($FilePath . ".conf");
    :set ConfigFile ($FileName . ".conf");
    :set Attach ($Attach, ($FilePath . ".conf"));
  } else={
    $LogPrintExit2 warning $0 ("Creating config file not possible. Limit is 4kB, configuration has " . \
        $Size . " bytes.") false;
    :set ConfigFile "failed";
    :set Failed 1;
  }
}

# send email with status and files
$SendEMail2 ({ origin=$0; \
  subject=[ $IfThenElse ($Failed > 0) \
    ([ $SymbolForNotification "floppy-disk,warning-sign" ] . "Backup & Config with failure") \
    ([ $SymbolForNotification "floppy-disk,incoming-envelope" ] . "Backup & Config") ]; \
  message=("See attached files for backup and config export for " . \
    $Identity . ".\n\n" . \
    [ $DeviceInfo ] . "\n\n" . \
    [ $FormatLine "Backup file" $BackupFile ] . "\n" . \
    [ $FormatLine "Export file" $ExportFile ] . "\n" . \
    [ $FormatLine "Config file" $ConfigFile ]); \
  attach=$Attach; remove-attach=true });

# wait for the mail to be sent
:local I 0;
:while ([ :len [ /file/find where name ~ ($FilePath . "\\.(backup|rsc)\$") ] ] > 0) do={
  :if ($I >= 120) do={
    $LogPrintExit2 warning $0 ("Files are still available, sending e-mail failed.") true;
  }
  :delay 1s;
  :set I ($I + 1);
}

:if ($Failed = 1) do={
  :error "An error occured!";
}
