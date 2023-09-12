#!rsc by RouterOS
# RouterOS script: backup-cloud
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: backup-script, order=40
#
# upload backup to MikroTik cloud
# https://git.eworm.de/cgit/routeros-scripts/about/doc/backup-cloud.md

:local 0 "backup-cloud";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global BackupPassword;
:global BackupRandomDelay;
:global Identity;

:global DeviceInfo;
:global FormatLine;
:global LogPrintExit2;
:global RandomDelay;
:global ScriptFromTerminal;
:global ScriptLock;
:global SendNotification2;
:global SymbolForNotification;
:global WaitFullyConnected;

$ScriptLock $0;
$WaitFullyConnected;

:if ([ $ScriptFromTerminal $0 ] = false && $BackupRandomDelay > 0) do={
  $RandomDelay $BackupRandomDelay;
}

:do {
  # we are not interested in output, but print is
  # required to fetch information from cloud
  /system/backup/cloud/print as-value;
  :if ([ :len [ /system/backup/cloud/find ] ] > 0) do={
    /system/backup/cloud/upload-file action=create-and-upload \
        password=$BackupPassword replace=[ get ([ find ]->0) name ];
  } else={
    /system/backup/cloud/upload-file action=create-and-upload \
        password=$BackupPassword;
  }
  :local Cloud [ /system/backup/cloud/get ([ find ]->0) ];

  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "floppy-disk,cloud" ] . "Cloud backup"); \
    message=("Uploaded backup for " . $Identity . " to cloud.\n\n" . \
      [ $DeviceInfo ] . "\n\n" . \
      [ $FormatLine "Name" ($Cloud->"name") ] . "\n" . \
      [ $FormatLine "Size" ($Cloud->"size" . " B (" . ($Cloud->"size" / 1024) . " KiB)") ] . "\n" . \
      [ $FormatLine "Download key" ($Cloud->"secret-download-key") ]); silent=true });
} on-error={
  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "floppy-disk,warning-sign" ] . "Cloud backup failed"); \
    message=("Failed uploading backup for " . $Identity . " to cloud!\n\n" . [ $DeviceInfo ]) });
  $LogPrintExit2 error $0 ("Failed uploading backup for " . $Identity . " to cloud!") true;
}
