#!rsc by RouterOS
# RouterOS script: check-perpetual-license
# Copyright (c) 2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# check perpetual license on CHR
# https://rsc.eworm.de/doc/check-perpetual-license.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global Identity;
  :global SentCertificateNotification;

  :global LogPrint;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  $WaitFullyConnected;

  :local License [ /system/license/get ];
  :if ([ :typeof ($License->"deadline-at") ] != "str") do={
    $LogPrint info $ScriptName ("This device does not have a perpetual license.");
    :set ExitOK true;
    :error true;
  }
  
  :if ([ :len ($License->"next-renewal-at") ] = 0 && ($License->"limited-upgrades") = true) do={
    $LogPrint warning $ScriptName ("Your license expired on " . ($License->"deadline-at") . "!");
    :if ($SentCertificateNotification != "expired") do={
      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "warning-sign" ] . "License expired!"); \
        message=("Your license expired on " . ($License->"deadline-at") . \
          ", can no longer update RouterOS on " . $Identity . "...") });
      :set SentCertificateNotification "expired";
    }
    :set ExitOK true;
    :error true;
  }

  :if ([ :totime ($License->"deadline-at") ] - 3w < [ :timestamp ]) do={
    $LogPrint warning $ScriptName ("Your license will expire on " . ($License->"deadline-at") . "!");
    :if ($SentCertificateNotification != "warning") do={
      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "warning-sign" ] . "License about to expire!"); \
        message=("Your license failed to renew and is about to expire on " . \
          ($License->"deadline-at") . " on " . $Identity . "...") });
      :set SentCertificateNotification "warning";
    }
    :set ExitOK true;
    :error true;
  }

  :if ([ :typeof $SentCertificateNotification ] = "str" && \
       [ :totime ($License->"deadline-at") ] - 4w > [ :timestamp ]) do={
    $LogPrint info $ScriptName ("Your license was successfully renewed.");
    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification "white-heavy-check-mark" ] . "License renewed"); \
      message=("Your license was successfully renewed on " . $Identity . \
        ". It is now valid until " . ($License->"deadline-at") . ".") });
    :set SentCertificateNotification;
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
