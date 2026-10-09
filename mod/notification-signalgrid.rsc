#!rsc by RouterOS
# RouterOS script: mod/notification-signalgrid
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
#                    2026 Signalgrid e.U. (https://signalgrid.co/)
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch, scheduler
#
# send notifications via Signalgrid (signalgrid.co)
# https://rsc.eworm.de/doc/mod/notification-signalgrid.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=notification-signalgrid, schema=128aca9359451217298096f284f1811957b4079d0693132dbe948f2ced909a78
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"notification-signalgrid.certificate.failed") "Downloading required certificate failed.";
:set ($LanguageEnglish->"notification-signalgrid.empty") "Flushing Signalgrid messages from scheduler, but queue is empty.";
:set ($LanguageEnglish->"notification-signalgrid.offline") "System is not fully connected, not flushing.";
:set ($LanguageEnglish->"notification-signalgrid.queue.failed") "Sending queued Signalgrid notification failed: {error}";
:set ($LanguageEnglish->"notification-signalgrid.queued") "This message was queued since {date} {time} and may be obsolete.";
:set ($LanguageEnglish->"notification-signalgrid.sending.failed") "Failed sending Signalgrid notification: {error} - Queuing...";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:global FlushSignalgridQueue;
:global NotificationFunctions;
:global PurgeSignalgridQueue;
:global SendSignalgrid;
:global SendSignalgrid2;

# flush Signalgrid queue
:set FlushSignalgridQueue do={ :onerror Err {
  :global SignalgridQueue;

  :global IsFullyConnected;
  :global LogPrint;
  :global Translate;

  :if ([ $IsFullyConnected ] = false) do={
    $LogPrint debug $0 [ $Translate "notification-signalgrid.offline" ];
    :return false;
  }

  :local AllDone true;
  :local QueueLen [ :len $SignalgridQueue ];

  :if ([ :len [ /system/scheduler/find where name="_FlushSignalgridQueue" ] ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 [ $Translate "notification-signalgrid.empty" ];
  }

  :foreach Id,Request in=$SignalgridQueue do={
    :if ([ :typeof $Request ] = "array") do={
      :onerror Err {
        /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
          http-header-field=($Request->"headers") http-data=($Request->"data") \
          "https://api.signalgrid.co/v1/push" as-value;
        :set ($SignalgridQueue->$Id);
      } do={
        $LogPrint debug $0 [ $Translate "notification-signalgrid.queue.failed" ({ error=$Err }) ];
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $SignalgridQueue ]) do={
    /system/scheduler/remove [ find where name="_FlushSignalgridQueue" ];
    :set SignalgridQueue;
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# send notification via Signalgrid - expects one array argument
:set ($NotificationFunctions->"signalgrid") do={
  :local Notification $1;

  :global Identity;
  :global IdentityExtra;
  :global SignalgridChannel;
  :global SignalgridChannelOverride;
  :global SignalgridClientKey;
  :global SignalgridClientKeyOverride;
  :global SignalgridQueue;

  :global CertificateAvailable;
  :global EitherOr;
  :global FetchUserAgentStr;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global SymbolForNotification;

  :local ClientKey [ $EitherOr ($SignalgridClientKeyOverride->($Notification->"origin")) \
      $SignalgridClientKey ];
  :local Channel [ $EitherOr ($SignalgridChannelOverride->($Notification->"origin")) \
      $SignalgridChannel ];

  :if ([ :len $ClientKey ] = 0 || [ :len $Channel ] = 0) do={
    :return false;
  }

  :local Title ("[" . $IdentityExtra . $Identity . "] " . ($Notification->"subject"));
  :local Body (($Notification->"message") . "\n");

  :if ([ :len ($Notification->"link") ] > 0) do={
    :set Body ($Body . "\n" . [ $SymbolForNotification "link" ] . ($Notification->"link"));
  }

  :local Headers ({ [ $FetchUserAgentStr ($Notification->"origin") ];
    "Content-Type: application/x-www-form-urlencoded" });

  :local Data ("client_key=" . [ :convert $ClientKey to=url ] . \
    "&channel=" . [ :convert $Channel to=url ] . \
    "&title=" . [ :convert $Title to=url ] . \
    "&type=" . [ $IfThenElse ($Notification->"silent") "info" "warn" ]);

  :onerror Err {
    :if ([ $CertificateAvailable "Root YE" "fetch" ] = false) do={
      $LogPrint warning $0 [ $Translate "notification-signalgrid.certificate.failed" ];
      :error false;
    }
    /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
      http-header-field=$Headers http-data=($Data . "&body=" . [ :convert $Body to=url ]) \
      "https://api.signalgrid.co/v1/push" as-value;
  } do={
    $LogPrint info $0 [ $Translate "notification-signalgrid.sending.failed" ({ error=$Err }) ];

    :if ([ :typeof $SignalgridQueue ] = "nothing") do={
      :set SignalgridQueue ({});
    }
    :set Body ($Body . "\n" . [ $SymbolForNotification "alarm-clock" ] . \
      [ $Translate "notification-signalgrid.queued" ({ date=[ /system/clock/get date ]; time=[ /system/clock/get time ] }) ]);
    :set ($SignalgridQueue->[ :len $SignalgridQueue ]) \
     { headers=$Headers; data=($Data . "&body=" . [ :convert $Body to=url ]) };
    :if ([ :len [ /system/scheduler/find where name="_FlushSignalgridQueue" ] ] = 0) do={
      /system/scheduler/add name="_FlushSignalgridQueue" interval=1m start-time=startup \
        on-event=(":global FlushSignalgridQueue; \$FlushSignalgridQueue;");
    }
  }
}

# purge the Signalgrid queue
:set PurgeSignalgridQueue do={
  :global SignalgridQueue;

  /system/scheduler/remove [ find where name="_FlushSignalgridQueue" ];
  :set SignalgridQueue;
}

# send notification via Signalgrid - expects at least two string arguments
:set SendSignalgrid do={ :onerror Err {
  :global SendSignalgrid2;

  $SendSignalgrid2 ({ origin=$0; subject=$1; message=$2; link=$3; silent=$4 });
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# send notification via Signalgrid - expects one array argument
:set SendSignalgrid2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"signalgrid") ("\$NotificationFunctions->\"signalgrid\"") $Notification;
}
