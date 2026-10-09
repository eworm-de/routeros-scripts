#!rsc by RouterOS
# RouterOS script: check-perpetual-license
# Copyright (c) 2025-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# check perpetual license on CHR
# https://rsc.eworm.de/doc/check-perpetual-license.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=check-perpetual-license, schema=32c55d22d323e366e19b8b016c5e836db00f7a8e885d0410216fa65ead84ab9d
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"check-perpetual-license.expired.log") "Your license expired on {date}!";
:set ($LanguageEnglish->"check-perpetual-license.expired.message") "Your license expired on {date}, can no longer update RouterOS on {identity}...";
:set ($LanguageEnglish->"check-perpetual-license.expired.subject") "License expired!";
:set ($LanguageEnglish->"check-perpetual-license.renewed.log") "Your license was successfully renewed.";
:set ($LanguageEnglish->"check-perpetual-license.renewed.message") "Your license was successfully renewed on {identity}. It is now valid until {date}.";
:set ($LanguageEnglish->"check-perpetual-license.renewed.subject") "License renewed";
:set ($LanguageEnglish->"check-perpetual-license.unsupported") "This device does not have a perpetual license.";
:set ($LanguageEnglish->"check-perpetual-license.warning.log") "Your license will expire on {date}!";
:set ($LanguageEnglish->"check-perpetual-license.warning.message") "Your license failed to renew and is about to expire on {date} on {identity}...";
:set ($LanguageEnglish->"check-perpetual-license.warning.subject") "License about to expire!";
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global Identity;
  :global SentCertificateNotification;

  :global Translate;
  :global LogPrint;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  $WaitFullyConnected;

  :local License [ /system/license/get ];
  :if ([ :typeof ($License->"deadline-at") ] != "str") do={
    $LogPrint info $ScriptName ([ $Translate "check-perpetual-license.unsupported" ]);
    :exit;
  }

  :if ([ :len ($License->"next-renewal-at") ] = 0 && ($License->"limited-upgrades") = true) do={
    $LogPrint warning $ScriptName ([ $Translate "check-perpetual-license.expired.log" ({ date=($License->"deadline-at") }) ]);
    :if ($SentCertificateNotification != "expired") do={
      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "scroll,cross-mark" ] . [ $Translate "check-perpetual-license.expired.subject" ]); \
        message=([ $Translate "check-perpetual-license.expired.message" ({ date=($License->"deadline-at"); identity=$Identity }) ]) });
      :set SentCertificateNotification "expired";
    }
    :exit;
  }

  :if ([ :totime ($License->"deadline-at") ] - 3w < [ :timestamp ]) do={
    $LogPrint warning $ScriptName ([ $Translate "check-perpetual-license.warning.log" ({ date=($License->"deadline-at") }) ]);
    :if ($SentCertificateNotification != "warning") do={
      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "scroll,warning-sign" ] . [ $Translate "check-perpetual-license.warning.subject" ]); \
        message=([ $Translate "check-perpetual-license.warning.message" ({ date=($License->"deadline-at"); identity=$Identity }) ]) });
      :set SentCertificateNotification "warning";
    }
    :exit;
  }

  :if ([ :typeof $SentCertificateNotification ] = "str" && \
       [ :totime ($License->"deadline-at") ] - 4w > [ :timestamp ]) do={
    $LogPrint info $ScriptName ([ $Translate "check-perpetual-license.renewed.log" ]);
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "scroll,white-heavy-check-mark" ] . [ $Translate "check-perpetual-license.renewed.subject" ]); \
      message=([ $Translate "check-perpetual-license.renewed.message" ({ identity=$Identity; date=($License->"deadline-at") }) ]) });
    :set SentCertificateNotification;
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
