#!rsc by RouterOS
# RouterOS script: mod/notification-gotify
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
#                         Leonardo David Monteiro <leo@cub3.xyz>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, fetch, scheduler
#
# send notifications via Gotify (gotify.net)
# https://rsc.eworm.de/doc/mod/notification-gotify.md

:global FlushGotifyQueue;
:global NotificationFunctions;
:global PurgeGotifyQueue;
:global SendGotify;
:global SendGotify2;

# flush Gotify queue
:set FlushGotifyQueue do={ :do {
  :global GotifyQueue;

  :global IsFullyConnected;
  :global LogPrint;

  :if ([ $IsFullyConnected ] = false) do={
    $LogPrint debug $0 ("System is not fully connected, not flushing.");
    :return false;
  }

  :local AllDone true;
  :local QueueLen [ :len $GotifyQueue ];

  :if ([ :len [ /system/scheduler/find where name="_FlushGotifyQueue" ] ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 ("Flushing Gotify messages from scheduler, but queue is empty.");
  }

  :foreach Id,Message in=$GotifyQueue do={
    :if ([ :typeof $Message ] = "array" ) do={
      :do {
        /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
          http-header-field=($Message->"headers") http-data=[ :serialize to=json ($Message->"message") ] \
          ($Message->"url") as-value;
        :set ($GotifyQueue->$Id);
      } on-error={
        $LogPrint debug $0 ("Sending queued Gotify message failed.");
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $GotifyQueue ]) do={
    /system/scheduler/remove [ find where name="_FlushGotifyQueue" ];
    :set GotifyQueue;
  }
} on-error={
  :global ExitError; $ExitError false $0;
} }

# send notification via Gotify - expects one array argument
:set ($NotificationFunctions->"gotify") do={
  :local Notification $1;

  :global Identity;
  :global IdentityExtra;
  :global GotifyQueue;
  :global GotifyServer;
  :global GotifyServerOverride;
  :global GotifyToken;
  :global GotifyTokenOverride;

  :global EitherOr;
  :global FetchUserAgentStr;
  :global IfThenElse;
  :global LogPrint;
  :global SymbolForNotification;

  :local Server [ $EitherOr ($GotifyServerOverride->($Notification->"origin")) $GotifyServer ];
  :local Token [ $EitherOr ($GotifyTokenOverride->($Notification->"origin")) $GotifyToken ];

  :if ([ :len $Token ] = 0) do={
    :return false;
  }

  :local Url ("https://" . $Server . "/message");
  :local Headers ({ [ $FetchUserAgentStr ($Notification->"origin") ]; \
    ("X-Gotify-Key: " . $Token); "Content-Type: application/json" });
  :local Message ({
    "title"=("[" . $IdentityExtra . $Identity . "] " . ($Notification->"subject")); \
    "message"=(($Notification->"message") . "\n" . [ $IfThenElse ([ :len ($Notification->"link") ] > 0) \
      ("\n" . [ $SymbolForNotification "link" ] . ($Notification->"link")) ]); \
    "priority"=[ :tonum [ $IfThenElse ($Notification->"silent") 2 5 ] ] });

  :do {
    /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
      http-header-field=$Headers http-data=[ :serialize to=json $Message ] $Url as-value;
  } on-error={
    $LogPrint info $0 ("Failed sending Gotify notification! Queuing...");

    :if ([ :typeof $GotifyQueue ] = "nothing") do={
      :set GotifyQueue ({});
    }
    :set ($Message->"message") (($Notification->"message") . "\n" . \
      [ $SymbolForNotification "alarm-clock" ] . "This message was queued since " . \
      [ /system/clock/get date ] . " " . [ /system/clock/get time ] . " and may be obsolete.");
    :set ($GotifyQueue->[ :len $GotifyQueue ]) \
      { url=$Url; headers=$Headers; message=$Message };
    :if ([ :len [ /system/scheduler/find where name="_FlushGotifyQueue" ] ] = 0) do={
      /system/scheduler/add name="_FlushGotifyQueue" interval=1m start-time=startup \
        on-event=(":global FlushGotifyQueue; \$FlushGotifyQueue;");
    }
  }
}

# purge the Gotify queue
:set PurgeGotifyQueue do={
  :global GotifyQueue;

  /system/scheduler/remove [ find where name="_FlushGotifyQueue" ];
  :set GotifyQueue;
}

# send notification via Gotify - expects at least two string arguments
:set SendGotify do={ :do {
  :global SendGotify2;

  $SendGotify2 ({ origin=$0; subject=$1; message=$2; link=$3; silent=$4 });
} on-error={
  :global ExitError; $ExitError false $0;
} }

# send notification via Gotify - expects one array argument
:set SendGotify2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"gotify") ("\$NotificationFunctions->\"gotify\"") $Notification;
}
