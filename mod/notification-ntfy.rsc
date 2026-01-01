#!rsc by RouterOS
# RouterOS script: mod/notification-ntfy
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, fetch, scheduler
#
# send notifications via Ntfy (ntfy.sh)
# https://rsc.eworm.de/doc/mod/notification-ntfy.md

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

  :if ([ $IsFullyConnected ] = false) do={
    $LogPrint debug $0 ("System is not fully connected, not flushing.");
    :return false;
  }

  :local AllDone true;
  :local QueueLen [ :len $NtfyQueue ];

  :if ([ :len [ /system/scheduler/find where name="_FlushNtfyQueue" ] ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 ("Flushing Ntfy messages from scheduler, but queue is empty.");
  }

  :foreach Id,Message in=$NtfyQueue do={
    :if ([ :typeof $Message ] = "array" ) do={
      :onerror Err {
        /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
          http-header-field=($Message->"headers") http-data=($Message->"text") \
          ($Message->"url") as-value;
        :set ($NtfyQueue->$Id);
      } do={
        $LogPrint debug $0 ("Sending queued Ntfy message failed: " . $Err);
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $NtfyQueue ]) do={
    /system/scheduler/remove [ find where name="_FlushNtfyQueue" ];
    :set NtfyQueue;
  }
} do={
  :global ExitError; $ExitError false $0 $Err;
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
  :global SymbolForNotification;
  :global UrlEncode;

  :local Server [ $EitherOr ($NtfyServerOverride->($Notification->"origin")) $NtfyServer ];
  :local User [ $EitherOr ($NtfyServerUserOverride->($Notification->"origin")) $NtfyServerUser ];
  :local Pass [ $EitherOr ($NtfyServerPassOverride->($Notification->"origin")) $NtfyServerPass ];
  :local Token [ $EitherOr ($NtfyServerTokenOverride->($Notification->"origin")) $NtfyServerToken ];
  :local Topic [ $EitherOr ($NtfyTopicOverride->($Notification->"origin")) $NtfyTopic ];

  :if ([ :len $Topic ] = 0) do={
    :return false;
  }

  :local Url ("https://" . $Server . "/" . [ $UrlEncode $Topic ]);
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
      :if ([ $CertificateAvailable "ISRG Root X1" "fetch" ] = false) do={
        $LogPrint warning $0 ("Downloading required certificate failed.");
        :error false;
      }
    }
    /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
      http-header-field=$Headers http-data=$Text $Url as-value;
  } do={
    $LogPrint info $0 ("Failed sending ntfy notification: " . $Err . " - Queuing...");

    :if ([ :typeof $NtfyQueue ] = "nothing") do={
      :set NtfyQueue ({});
    }
    :set Text ($Text . "\n" . [ $SymbolForNotification "alarm-clock" ] . \
      "This message was queued since " . [ /system/clock/get date ] . " " . \
      [ /system/clock/get time ] . " and may be obsolete.");
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
  :global ExitError; $ExitError false $0 $Err;
} }

# send notification via ntfy - expects one array argument
:set SendNtfy2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"ntfy") ("\$NotificationFunctions->\"ntfy\"") $Notification;
}
