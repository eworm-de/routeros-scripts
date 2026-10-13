#!rsc by RouterOS
# RouterOS script: backup-email
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: backup-script, order=20
# requires RouterOS, version=7.22
#
# create and email backup and config file
# https://rsc.eworm.de/doc/backup-email.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=backup-email, schema=d64d6ec60b1db0d5105ecd3ee2f9ce710886b1860f5d2ef971c4aa2adcdf6722
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"backup-email.directory") "Failed creating directory!";
:set ($LanguageEnglish->"backup-email.email.failed") "Files are still available, sending e-mail failed.";
:set ($LanguageEnglish->"backup-email.email.unavailable") "The module for sending notifications via e-mail is not installed.";
:set ($LanguageEnglish->"backup-email.files.available") "Files are still available.";
:set ($LanguageEnglish->"backup-email.label.backup") "Backup file";
:set ($LanguageEnglish->"backup-email.label.config") "Config file";
:set ($LanguageEnglish->"backup-email.label.export") "Export file";
:set ($LanguageEnglish->"backup-email.message") "See attached files for backup and config export for {identity}.\0A\0A{device}\0A\0A{details}";
:set ($LanguageEnglish->"backup-email.none") "none";
:set ($LanguageEnglish->"backup-email.options") "Configured to send neither backup nor config export.";
:set ($LanguageEnglish->"backup-email.partition") "Running from backup partition, refusing to act.";
:set ($LanguageEnglish->"backup-email.subject") "Backup & Config";
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
  :global Domain;
  :global Identity;
  :global PackagesUpdateBackupFailure;

  :global CleanName;
  :global DeviceInfo;
  :global FileExists;
  :global IfThenElse;
  :global FormatLine;
  :global Translate;
  :global LogPrint;
  :global MkDir;
  :global RandomDelay;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global SendEMail2;
  :global SymbolForNotification;
  :global WaitForFile;
  :global WaitFullyConnected;

  :if ([ :typeof $SendEMail2 ] = "nothing") do={
    $LogPrint error $ScriptName ([ $Translate "backup-email.email.unavailable" ]);
    :exit;
  }

  :if ($BackupSendBinary != true && \
       $BackupSendExport != true) do={
    $LogPrint error $ScriptName ([ $Translate "backup-email.options" ]);
    :exit;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  :if ([ :len [ /system/scheduler/find where name="running-from-backup-partition" ] ] > 0) do={
    $LogPrint warning $ScriptName ([ $Translate "backup-email.partition" ]);
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
  :local Attach ({});

  :if ([ $MkDir $DirName ] = false) do={
    $LogPrint error $ScriptName ([ $Translate "backup-email.directory" ]);
    :exit;
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
      [ $Translate "backup-email.subject" ]); \
    message=([ $Translate "backup-email.message" ({ identity=$Identity; device=[ $DeviceInfo ]; details=([ $FormatLine [ $Translate "backup-email.label.backup" ] [ $IfThenElse ($BackupFile = "none") [ $Translate "backup-email.none" ] $BackupFile ] ] . "\n" . \
      [ $FormatLine [ $Translate "backup-email.label.export" ] [ $IfThenElse ($ExportFile = "none") [ $Translate "backup-email.none" ] $ExportFile ] ] . "\n" . \
      [ $FormatLine [ $Translate "backup-email.label.config" ] [ $IfThenElse ($ConfigFile = "none") [ $Translate "backup-email.none" ] $ConfigFile ] ]) }) ]); \
    attach=$Attach; remove-attach=true });

  # wait for the mail to be sent
  :do {
    :retry {
      :if ([ $FileExists ($FilePath . ".conf") ".conf file" ] = true || \
           [ $FileExists ($FilePath . ".backup") "backup" ] = true || \
           [ $FileExists ($FilePath . ".rsc") "script" ] = true) do={
        :error [ $Translate "backup-email.files.available" ];
      }
    } delay=1s max=120;
  } on-error={
    $LogPrint warning $ScriptName ([ $Translate "backup-email.email.failed" ]);
    :set PackagesUpdateBackupFailure true;
  }
  # do not remove the files here, as the mail is still queued!
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
