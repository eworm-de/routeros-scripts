#!rsc by RouterOS
# RouterOS script: backup-partition
# Copyright (c) 2022-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: backup-script, order=70
# requires RouterOS, version=7.22
# requires device-mode, scheduler
#
# save configuration to fallback partition
# https://rsc.eworm.de/doc/backup-partition.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=backup-partition, schema=d37495d3faf22763093e64eb8145eb90d29a006fb0503cc939337741dfd80681
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"backup-partition.copied") "Copied RouterOS to partition '{name}'.";
:set ($LanguageEnglish->"backup-partition.copy.failed") "Failed copying RouterOS to partition '{name}': {error}";
:set ($LanguageEnglish->"backup-partition.fallback.missing") "There is no inactive partition named '{name}'.";
:set ($LanguageEnglish->"backup-partition.inactive") "Device is not running from active partition.";
:set ($LanguageEnglish->"backup-partition.partition") "Running from backup partition, refusing to act.";
:set ($LanguageEnglish->"backup-partition.prompt") "The partitions have different RouterOS versions. Copy over to '{name}'? [y/N]";
:set ($LanguageEnglish->"backup-partition.running") "Running from partition '{name}'!";
:set ($LanguageEnglish->"backup-partition.save.failed") "Failed saving configuration to partition '{name}': {error}";
:set ($LanguageEnglish->"backup-partition.saved") "Saved configuration to partition '{name}'.";
:set ($LanguageEnglish->"backup-partition.unavailable") "Device does not have a fallback partition.";
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

  :global BackupPartitionCopyBeforeFeatureUpdate;
  :global PackagesUpdateBackupFailure;

  :global Translate;
  :global LogPrint;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global VersionToNum;

  :local CopyTo do={
    :local ScriptName [ :tostr $1 ];
    :local FallbackTo [ :toid  $2 ];
    :local PartName   [ :tostr $3 ];

    :global Translate;
    :global LogPrint;

    :onerror Err {
      /partitions/copy-to $FallbackTo;
      $LogPrint info $ScriptName ([ $Translate "backup-partition.copied" ({ name=$PartName }) ]);
    } do={
      $LogPrint error $ScriptName ([ $Translate "backup-partition.copy.failed" ({ name=$PartName; error=$Err }) ]);
      :return false;
    }
    :return true;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  :if ([ :len [ /system/scheduler/find where name="running-from-backup-partition" ] ] > 0) do={
    $LogPrint warning $ScriptName ([ $Translate "backup-partition.partition" ]);
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  :if ([ :len [ /partitions/find ] ] < 2) do={
    $LogPrint error $ScriptName ([ $Translate "backup-partition.unavailable" ]);
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  :local ActiveRunning [ /partitions/find where active running ];

  :if ([ :len $ActiveRunning ] < 1) do={
    $LogPrint error $ScriptName ([ $Translate "backup-partition.inactive" ]);
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  :local ActiveRunningVal [ /partitions/get $ActiveRunning ];
  :local FallbackTo [ /partition/find where name=($ActiveRunningVal->"fallback-to") !active ];

  :if ([ :len $FallbackTo ] < 1) do={
    $LogPrint error $ScriptName ([ $Translate "backup-partition.fallback.missing" ({ name=($ActiveRunningVal->"fallback-to") }) ]);
    :set PackagesUpdateBackupFailure true;
    :exit;
  }

  :local FallbackToVal [ /partition/get $FallbackTo ];

  :if ($ActiveRunningVal->"version" != $FallbackToVal->"version") do={
    :local Once 1;
    :while ($Once) do={
      :set Once 0;

      :if ($FallbackToVal->"version" = "EMPTY") do={
        :if ([ $CopyTo $ScriptName $FallbackTo ($FallbackToVal->"name") ] = false) do={
          :set PackagesUpdateBackupFailure true;
          :exit;
        }
        :continue;
      }

      :if ([ $ScriptFromTerminal $ScriptName ] = true) do={
        :put ([ $Translate "backup-partition.prompt" ({ name=($FallbackToVal->"name") }) ]);
        :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
          :if ([ $CopyTo $ScriptName $FallbackTo ($FallbackToVal->"name") ] = false) do={
            :set PackagesUpdateBackupFailure true;
            :exit;
          }
        }
        :continue;
      }

      :local Update [ /system/package/update/get ];
      :local NumInstalled [ $VersionToNum ($Update->"installed-version") ];
      :local NumLatest [ $VersionToNum ($Update->"latest-version") ];
      :local BitMask [ $VersionToNum "255.255zero0" ];
      :if ($BackupPartitionCopyBeforeFeatureUpdate = true && $NumLatest > 0 && \
           ($NumInstalled & $BitMask) != ($NumLatest & $BitMask)) do={
        :if ([ $CopyTo $ScriptName $FallbackTo ($FallbackToVal->"name") ] = false) do={
          :set PackagesUpdateBackupFailure true;
          :exit;
        }
      }
    }
  }

  # Capture the chosen language; this startup warning runs before core helpers.
  # Hex encoding keeps catalog text inert inside the deferred scheduler source.
  :onerror Err {
    /system/scheduler/add start-time=startup name="running-from-backup-partition" \
        on-event=(":local Text [ :convert from=hex to=raw \"" . \
        [ :convert from=raw to=hex [ $Translate "backup-partition.running" ({ name="__PARTITION_NAME__" }) ] ] . \
        "\" ]; :local Name [ /partitions/get [ find where running ] name ]; " . \
        ":local Message \"\"; :local Start [ :find \$Text \"__PARTITION_NAME__\" ]; " . \
        ":while ([ :typeof \$Start ] = \"num\") do={ " . \
        ":set Message (\$Message . [ :pick \$Text 0 \$Start ] . \$Name); " . \
        ":set Text [ :pick \$Text (\$Start + 18) [ :len \$Text ] ]; " . \
        ":set Start [ :find \$Text \"__PARTITION_NAME__\" ]; }; " . \
        ":log warning (\$Message . \$Text);");
    /partitions/save-config-to $FallbackTo;
    /system/scheduler/remove "running-from-backup-partition";
    $LogPrint info $ScriptName ([ $Translate "backup-partition.saved" ({ name=($FallbackToVal->"name") }) ]);
  } do={
    /system/scheduler/remove [ find where name="running-from-backup-partition" ];
    $LogPrint error $ScriptName ([ $Translate "backup-partition.save.failed" ({ name=($FallbackToVal->"name"); error=$Err }) ]);
    :set PackagesUpdateBackupFailure true;
    :exit;
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
