#!rsc by RouterOS
# RouterOS script: mod/notification-ntfy
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch, scheduler
#
# send notifications via Ntfy (ntfy.sh)
# https://rsc.eworm.de/doc/mod/notification-ntfy.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=notification-ntfy, schema=6734a9715e6b789bb7ff475fdc9f2b11391a7dcbd94aaef3413d695b035d493e
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"notification-ntfy.certificate.failed") "Downloading required certificate failed.";
:set ($LanguageEnglish->"notification-ntfy.offline") "System is not fully connected, not flushing.";
:set ($LanguageEnglish->"notification-ntfy.queue.empty") "Flushing Ntfy messages from scheduler, but queue is empty.";
:set ($LanguageEnglish->"notification-ntfy.queue.failed") "Sending queued Ntfy message failed: {error}";
:set ($LanguageEnglish->"notification-ntfy.queued") "This message was queued since {date} {time} and may be obsolete.";
:set ($LanguageEnglish->"notification-ntfy.send.failed") "Failed sending ntfy notification: {error} - Queuing...";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:global FlushNtfyQueue;
:global NotificationFunctions;
:global PurgeNtfyQueue;
:global SendNtfy;
:global SendNtfy2;

# flush ntfy queue
:set FlushNtfyQueue do={ :onerror Err {
  :global NtfyQueue;

  :global IsFullyConnected;
  :global LogPrint;
  :global Translate;

  :if ([ $IsFullyConnected ] = false) do={
    $LogPrint debug $0 [ $Translate "notification-ntfy.offline" ];
    :return false;
  }

  :local AllDone true;
  :local QueueLen [ :len $NtfyQueue ];

  :if ([ :len [ /system/scheduler/find where name="_FlushNtfyQueue" ] ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 [ $Translate "notification-ntfy.queue.empty" ];
  }

  :foreach Id,Message in=$NtfyQueue do={
    :if ([ :typeof $Message ] = "array" ) do={
      :onerror Err {
        /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
          http-header-field=($Message->"headers") http-data=($Message->"text") \
          ($Message->"url") as-value;
        :set ($NtfyQueue->$Id);
      } do={
        $LogPrint debug $0 [ $Translate "notification-ntfy.queue.failed" \
            ({ error=$Err }) ];
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $NtfyQueue ]) do={
    /system/scheduler/remove [ find where name="_FlushNtfyQueue" ];
    :set NtfyQueue;
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# send notification via ntfy - expects one array argument
:set ($NotificationFunctions->"ntfy") do={
  :local Notification $1;

  :global Identity;
  :global IdentityExtra;
  :global NtfyQueue;
  :global NtfyServer;
  :global NtfyServerOverride;
  :global NtfyServerPass;
  :global NtfyServerPassOverride;
  :global NtfyServerToken;
  :global NtfyServerTokenOverride;
  :global NtfyServerUser;
  :global NtfyServerUserOverride;
  :global NtfyTopic;
  :global NtfyTopicOverride;

  :global CertificateAvailable;
  :global EitherOr;
  :global FetchUserAgentStr;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global SymbolForNotification;

  :local Server [ $EitherOr ($NtfyServerOverride->($Notification->"origin")) $NtfyServer ];
  :local User [ $EitherOr ($NtfyServerUserOverride->($Notification->"origin")) $NtfyServerUser ];
  :local Pass [ $EitherOr ($NtfyServerPassOverride->($Notification->"origin")) $NtfyServerPass ];
  :local Token [ $EitherOr ($NtfyServerTokenOverride->($Notification->"origin")) $NtfyServerToken ];
  :local Topic [ $EitherOr ($NtfyTopicOverride->($Notification->"origin")) $NtfyTopic ];

  :if ([ :len $Topic ] = 0) do={
    :return false;
  }

  :local Url ("https://" . $Server . "/" . [ :convert to=url $Topic ]);
  :local Headers ({ [ $FetchUserAgentStr ($Notification->"origin") ]; \
    ("Priority: " . [ $IfThenElse ($Notification->"silent") "low" "default" ]); \
    ("Title: " . "[" . $IdentityExtra . $Identity . "] " . ($Notification->"subject")) });
  :if ([ :len $User ] > 0 || [ :len $Pass ] > 0) do={
    :set Headers ($Headers, ("Authorization: Basic " . [ :convert to=base64 ($User . ":" . $Pass) ]));
  }
  :if ([ :len $Token ] > 0) do={
    :set Headers ($Headers, ("Authorization: Bearer " . $Token));
  }
  :local Text (($Notification->"message") . "\n");
  :if ([ :len ($Notification->"link") ] > 0) do={
    :set Text ($Text . "\n" . [ $SymbolForNotification "link" ] . ($Notification->"link"));
  }

  :onerror Err {
    :if ($Server = "ntfy.sh") do={
      :if ([ $CertificateAvailable "Root YR" "fetch" ] = false) do={
        $LogPrint warning $0 [ $Translate "notification-ntfy.certificate.failed" ];
        :error false;
      }
    }
    /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
      http-header-field=$Headers http-data=$Text $Url as-value;
  } do={
    $LogPrint info $0 [ $Translate "notification-ntfy.send.failed" \
        ({ error=$Err }) ];

    :if ([ :typeof $NtfyQueue ] = "nothing") do={
      :set NtfyQueue ({});
    }
    :set Text ($Text . "\n" . [ $SymbolForNotification "alarm-clock" ] . \
      [ $Translate "notification-ntfy.queued" \
          ({ date=[ /system/clock/get date ]; time=[ /system/clock/get time ] }) ]);
    :set ($NtfyQueue->[ :len $NtfyQueue ]) \
      { url=$Url; headers=$Headers; text=$Text };
    :if ([ :len [ /system/scheduler/find where name="_FlushNtfyQueue" ] ] = 0) do={
      /system/scheduler/add name="_FlushNtfyQueue" interval=1m start-time=startup \
        on-event=(":global FlushNtfyQueue; \$FlushNtfyQueue;");
    }
  }
}

# purge the Ntfy queue
:set PurgeNtfyQueue do={
  :global NtfyQueue;

  /system/scheduler/remove [ find where name="_FlushNtfyQueue" ];
  :set NtfyQueue;
}

# send notification via ntfy - expects at least two string arguments
:set SendNtfy do={ :onerror Err {
  :global SendNtfy2;

  $SendNtfy2 ({ origin=$0; subject=$1; message=$2; link=$3; silent=$4 });
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# send notification via ntfy - expects one array argument
:set SendNtfy2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"ntfy") ("\$NotificationFunctions->\"ntfy\"") $Notification;
}
