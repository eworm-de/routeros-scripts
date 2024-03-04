#!rsc by RouterOS
# RouterOS script: backup-email
# Copyright (c) 2013-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: backup-script, order=20
# requires RouterOS, version=7.12
#
# create and email backup and config file
# https://git.eworm.de/cgit/routeros-scripts/about/doc/backup-email.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local Main do={
  :local ScriptName [ :tostr $1 ];

  :global BackupPassword;
  :global BackupRandomDelay;
  :global BackupSendBinary;
  :global BackupSendExport;
  :global BackupSendGlobalConfig;
  :global Domain;
  :global Identity;

  :global CleanName;
  :global DeviceInfo;
  :global FormatLine;
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
    $LogPrintExit2 error $ScriptName ("The module for sending notifications via e-mail is not installed.") true;
  }

  :if ($BackupSendBinary != true && \
       $BackupSendExport != true) do={
    $LogPrintExit2 error $ScriptName ("Configured to send neither backup nor config export.") true;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :return false;
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
  :local Attach ({});

  :if ([ $MkDir $DirName ] = false) do={
    $LogPrintExit2 error $ScriptName ("Failed creating directory!") true;
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
    # Do *NOT* use '/file/add ...' here, as it is limited to 4095 bytes!
    :execute script={ :put [ /system/script/get global-config-overlay source ]; } \
        file=($FilePath . ".conf\00");
    $WaitForFile ($FilePath . ".conf");
    :set ConfigFile ($FileName . ".conf");
    :set Attach ($Attach, ($FilePath . ".conf"));
  }

  # send email with status and files
  $SendEMail2 ({ origin=$ScriptName; \
    subject=([ $SymbolForNotification "floppy-disk,incoming-envelope" ] . \
      "Backup & Config"); \
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
      $LogPrintExit2 warning $ScriptName ("Files are still available, sending e-mail failed.") true;
    }
    :delay 1s;
    :set I ($I + 1);
  }
}

$Main [ :jobname ];
