#!rsc by RouterOS
# RouterOS script: backup-partition
# Copyright (c) 2022-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: backup-script, order=70
#
# save configuration to fallback partition
# https://git.eworm.de/cgit/routeros-scripts/about/doc/backup-partition.md

:local 0 "backup-partition";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global LogPrintExit2;
:global ScriptLock;

$ScriptLock $0;

:if ([ :len [ /partitions/find ] ] < 2) do={
  $LogPrintExit2 error $0 ("Device does not have a fallback partition.") true;
}

:local ActiveRunning [ /partitions/find where active running ];

:if ([ :len $ActiveRunning ] < 1) do={
  $LogPrintExit2 error $0 ("Device is not running from active partition.") true;
}

:local ActiveRunningVar [ /partitions/get $ActiveRunning ];

:do {
  /partitions/save-config-to ($ActiveRunningVar->"fallback-to");
  $LogPrintExit2 info $0 ("Saved configuration to partition '" . \
      ($ActiveRunningVar->"fallback-to") . "'.") false;
} on-error={
  $LogPrintExit2 error $0 ("Failed saving configuration to partition '" . \
      ($ActiveRunningVar->"fallback-to") . "'!") true;
}
