#!rsc by RouterOS
# RouterOS script: ospf-to-leds
# Copyright (c) 2020-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.13
#
# visualize ospf instance state via leds
# https://git.eworm.de/cgit/routeros-scripts/about/doc/ospf-to-leds.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :error false;
  }

  :foreach Instance in=[ /routing/ospf/instance/find where comment~"^ospf-to-leds," ] do={
    :local InstanceVal [ /routing/ospf/instance/get $Instance ];
    :local LED ([ $ParseKeyValueStore ($InstanceVal->"comment") ]->"leds");
    :local LEDType [ /system/leds/get [ find where leds=$LED ] type ];

    :local NeighborCount 0;
    :foreach Area in=[ /routing/ospf/area/find where instance=($InstanceVal->"name") ] do={
      :local AreaName [ /routing/ospf/area/get $Area name ];
      :set NeighborCount ($NeighborCount + [ :len [ /routing/ospf/neighbor/find where area=$AreaName ] ]);
    }

    :if ($NeighborCount > 0 && $LEDType = "off") do={
      $LogPrint info $ScriptName ("OSPF instance " . $InstanceVal->"name" . " has " . $NeighborCount . " neighbors, led on!");
      /system/leds/set type=on [ find where leds=$LED ];
    }
    :if ($NeighborCount = 0 && $LEDType = "on") do={
      $LogPrint info $ScriptName ("OSPF instance " . $InstanceVal->"name" . " has no neighbors, led off!");
      /system/leds/set type=off [ find where leds=$LED ];
    }
  }
} on-error={ }
