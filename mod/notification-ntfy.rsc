#!rsc by RouterOS
# RouterOS script: mod/notification-ntfy
# Copyright (c) 2013-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.13
#
# send notifications via Ntfy (ntfy.sh)
# https://git.eworm.de/cgit/routeros-scripts/about/doc/mod/notification-ntfy.md

:global FlushNtfyQueue;
:global NotificationFunctions;
:global PurgeNtfyQueue;
:global SendNtfy;
:global SendNtfy2;

# flush ntfy queue
:set FlushNtfyQueue do={
  :global NtfyQueue;
  :global NtfyMessageIDs;

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
      :do {
        /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
          ($Message->"url") http-header-field=($Message->"headers") http-data=($Message->"text") as-value;
        :set ($NtfyQueue->$Id);
      } on-error={
        $LogPrint debug $0 ("Sending queued Ntfy message failed.");
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $NtfyQueue ]) do={
    /system/scheduler/remove [ find where name="_FlushNtfyQueue" ];
    :set NtfyQueue;
  }
}

# send notification via ntfy - expects one array argument
:set ($NotificationFunctions->"ntfy") do={
  :local Notification $1;

  :global Identity;
  :global IdentityExtra;
  :global NtfyQueue;
  :global NtfyServer;
  :global NtfyServerOverride;
  :global NtfyTopic;
  :global NtfyTopicOverride;

  :global CertificateAvailable;
  :global EitherOr;
  :global IfThenElse;
  :global LogPrint;
  :global SymbolForNotification;
  :global UrlEncode;

  :local Server [ $EitherOr ($NtfyServerOverride->($Notification->"origin")) $NtfyServer ];
  :local Topic [ $EitherOr ($NtfyTopicOverride->($Notification->"origin")) $NtfyTopic ];

  :if ([ :len $Topic ] = 0) do={
    :return false;
  }

  :local Url ("https://" . $NtfyServer . "/" . [ $UrlEncode $NtfyTopic ]);
  :local Headers ({ ("Priority: " . [ $IfThenElse ($Notification->"silent") "low" "default" ]); \
    ("Title: " . "[" . $IdentityExtra . $Identity . "] " . ($Notification->"subject")) });
  :local Text (($Notification->"message") . "\n");
  :if ([ :len ($Notification->"link") ] > 0) do={
    :set Text ($Text . "\n" . [ $SymbolForNotification "link" ] . ($Notification->"link"));
  }

  :do {
    :if ($NtfyServer = "ntfy.sh") do={
      :if ([ $CertificateAvailable "R3" ] = false) do={
        $LogPrint warning $0 ("Downloading required certificate failed.");
        :error false;
      }
    }
    /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
      $Url http-header-field=$Headers http-data=$Text as-value;
  } on-error={
    $LogPrint info $0 ("Failed sending ntfy notification! Queuing...");

    :if ([ :typeof $NtfyQueue ] = "nothing") do={
      :set NtfyQueue ({});
    }
    :set Text ($Text . "\n" . [ $SymbolForNotification "alarm-clock" ] . \
      "This message was queued since " . [ /system/clock/get date ] . " " . \
      [ /system/clock/get time ] . " and may be obsolete.");
    :set ($NtfyQueue->[ :len $NtfyQueue ]) { url=$Url; headers=$Headers; text=$Text };
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
:set SendNtfy do={
  :global SendNtfy2;

  $SendNtfy2 ({ origin=$0; subject=$1; message=$2; link=$3; silent=$4 });
}

# send notification via ntfy - expects one array argument
:set SendNtfy2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"ntfy") ("\$NotificationFunctions->\"ntfy\"") $Notification;
}
