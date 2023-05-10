#!rsc by RouterOS
# RouterOS script: daily-psk%TEMPL%
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# update daily PSK (pre shared key)
# https://git.eworm.de/cgit/routeros-scripts/about/doc/daily-psk.md
#
# !! This is just a template! Replace '%PATH%' with 'caps-man'
# !! or 'interface wireless'!

:local 0 "daily-psk%TEMPL%";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global DailyPskMatchComment;
:global DailyPskQrCodeUrl;
:global Identity;

:global FormatLine;
:global LogPrintExit2;
:global SendNotification2;
:global SymbolForNotification;
:global UrlEncode;
:global WaitForFile;
:global WaitFullyConnected;

$WaitFullyConnected;

# return pseudo-random string for PSK
:local GeneratePSK do={
  :local Date [ :tostr $1 ];

  :global DailyPskSecrets;

  :global ParseDate;

  :set Date [ $ParseDate $Date ];

  :local A ((14 - ($Date->"month")) / 12);
  :local B (($Date->"year") - $A);
  :local C (($Date->"month") + 12 * $A - 2);
  :local WeekDay (7000 + ($Date->"day") + $B + ($B / 4) - ($B / 100) + ($B / 400) + ((31 * $C) / 12));
  :set WeekDay ($WeekDay - (($WeekDay / 7) * 7));

  :return (($DailyPskSecrets->0->(($Date->"day") - 1)) . \
    ($DailyPskSecrets->1->(($Date->"month") - 1)) . \
    ($DailyPskSecrets->2->$WeekDay));
}

:local Seen ({});
:local Date [ /system/clock/get date ];
:local NewPsk [ $GeneratePSK $Date ];

:foreach AccList in=[ /%PATH%/access-list/find where comment~$DailyPskMatchComment ] do={
  :local IntName [ /interface/wireless/access-list/get $AccList interface ];
  :local Ssid [ /interface/wireless/get $IntName ssid ];
  :local OldPsk [ /interface/wireless/access-list/get $AccList private-pre-shared-key ];
  # /interface/wireless above - /caps-man below
  :local SsidRegExp [ /caps-man/access-list/get $AccList ssid-regexp ];
  :local Configuration ([ /caps-man/configuration/find where ssid~$SsidRegExp ]->0);
  :local Ssid [ /caps-man/configuration/get $Configuration ssid ];
  :local OldPsk [ /caps-man/access-list/get $AccList private-passphrase ];
  :local Skip 0;

  :if ($NewPsk != $OldPsk) do={
    $LogPrintExit2 info $0 ("Updating daily PSK for " . $Ssid . " to " . $NewPsk . " (was " . $OldPsk . ")") false;
    /interface/wireless/access-list/set $AccList private-pre-shared-key=$NewPsk;
    /caps-man/access-list/set $AccList private-passphrase=$NewPsk;

    :if ([ :len [ /interface/wireless/find where name=$IntName !disabled ] ] = 1) do={
    :if ([ :len [ /caps-man/actual-interface-configuration/find where configuration.ssid=$Ssid !disabled ] ] > 0) do={
      :foreach SeenSsid in=$Seen do={
        :if ($SeenSsid = $Ssid) do={
          $LogPrintExit2 debug $0 ("Already sent a mail for SSID " . $Ssid . ", skipping.") false;
          :set Skip 1;
        }
      }

      :if ($Skip = 0) do={
        :set Seen ($Seen, $Ssid);
        :local Link ($DailyPskQrCodeUrl . \
            "?scale=8&level=1&ssid=" . [ $UrlEncode $Ssid ] . "&pass=" . [ $UrlEncode $NewPsk ]);
        $SendNotification2 ({ origin=$0; \
          subject=([ $SymbolForNotification "calendar" ] . "daily PSK " . $Ssid); \
          message=("This is the daily PSK on " . $Identity . ":\n\n" . \
            [ $FormatLine "SSID" $Ssid ] . "\n" . \
            [ $FormatLine "PSK" $NewPsk ] . "\n" . \
            [ $FormatLine "Date" $Date ] . "\n\n" . \
            "A client device specific rule must not exist!"); link=$Link });
      }
    }
  }
}
