#!rsc by RouterOS
# RouterOS script: ospf-to-leds
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# visualize ospf instance state via leds
# https://rsc.eworm.de/doc/ospf-to-leds.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=ospf-to-leds, schema=3ae94f59ba09e39d125716de2e5770c50637c8553a2b9dcfe750e4b2f06ecb8e
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"ospf-to-leds.off") "OSPF instance {name} has no neighbors, led off!";
:set ($LanguageEnglish->"ospf-to-leds.on") "OSPF instance {name} has {count} neighbors, led on!";
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
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
      $LogPrint info $ScriptName [ $Translate "ospf-to-leds.on" \
          ({ name=($InstanceVal->"name"); count=$NeighborCount }) ];
      /system/leds/set type=on [ find where leds=$LED ];
    }
    :if ($NeighborCount = 0 && $LEDType = "on") do={
      $LogPrint info $ScriptName [ $Translate "ospf-to-leds.off" \
          ({ name=($InstanceVal->"name") }) ];
      /system/leds/set type=off [ find where leds=$LED ];
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
