#!rsc by RouterOS
# RouterOS script: capsman-rolling-upgrade%TEMPL%
# Copyright (c) 2018-2024 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: capsman-rolling-upgrade
# requires RouterOS, version=7.12
#
# upgrade CAPs one after another
# https://git.eworm.de/cgit/routeros-scripts/about/doc/capsman-rolling-upgrade.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local Main do={
  :local ScriptName [ :tostr $1 ];

  :global LogPrintExit2;
  :global ScriptLock;

  $ScriptLock $ScriptName;

  :local InstalledVersion [ /system/package/update/get installed-version ];

  :local RemoteCapCount [ :len [ /caps-man/remote-cap/find ] ];
  :local RemoteCapCount [ :len [ /interface/wifi/capsman/remote-cap/find ] ];
  :local RemoteCapCount [ :len [ /interface/wifiwave2/capsman/remote-cap/find ] ];
  :if ($RemoteCapCount > 0) do={
    :local Delay (600 / $RemoteCapCount);
    :if ($Delay > 120) do={ :set Delay 120; }
    :foreach RemoteCap in=[ /caps-man/remote-cap/find where version!=$InstalledVersion ] do={
    :foreach RemoteCap in=[ /interface/wifi/capsman/remote-cap/find where version!=$InstalledVersion ] do={
    :foreach RemoteCap in=[ /interface/wifiwave2/capsman/remote-cap/find where version!=$InstalledVersion ] do={
      :local RemoteCapVal [ /caps-man/remote-cap/get $RemoteCap ];
      :local RemoteCapVal [ /interface/wifi/capsman/remote-cap/get $RemoteCap ];
      :local RemoteCapVal [ /interface/wifiwave2/capsman/remote-cap/get $RemoteCap ];
      :if ([ :len $RemoteCapVal ] > 1) do={
# NOT /caps-man/ #
        :set ($RemoteCapVal->"name") ($RemoteCapVal->"common-name");
# NOT /caps-man/ #
        $LogPrintExit2 info $ScriptName ("Starting upgrade for " . $RemoteCapVal->"name" . \
          " (" . $RemoteCapVal->"identity" . ")...") false;
        /caps-man/remote-cap/upgrade $RemoteCap;
        /interface/wifi/capsman/remote-cap/upgrade $RemoteCap;
        /interface/wifiwave2/capsman/remote-cap/upgrade $RemoteCap;
      } else={
        $LogPrintExit2 warning $ScriptName ("Remote CAP vanished, skipping upgrade.") false;
      }
      :delay ($Delay . "s");
    }
  }
}

$Main [ :jobname ];
