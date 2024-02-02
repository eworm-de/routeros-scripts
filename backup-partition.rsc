#!rsc by RouterOS
# RouterOS script: backup-partition
# Copyright (c) 2022-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: backup-script, order=70
# requires RouterOS, version=7.12
#
# save configuration to fallback partition
# https://git.eworm.de/cgit/routeros-scripts/about/doc/backup-partition.md

:local 0 [ :jobname ];
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

:local FallbackTo [ /partitions/get $ActiveRunning fallback-to ];

:do {
  /partitions/save-config-to $FallbackTo;
  $LogPrintExit2 info $0 ("Saved configuration to partition '" . \
      $FallbackTo . "'.") false;
} on-error={
  $LogPrintExit2 error $0 ("Failed saving configuration to partition '" . \
      $FallbackTo . "'!") true;
}
