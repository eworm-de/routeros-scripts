#!rsc by RouterOS
# RouterOS script: mod/notification-signalgrid
# Copyright (c) 2026 Signalgrid
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch, scheduler
#
# send notifications via Signalgrid (signalgrid.co)
# https://rsc.eworm.de/doc/mod/notification-signalgrid.md

:global FlushSignalgridQueue;
:global NotificationFunctions;
:global PurgeSignalgridQueue;
:global SendSignalgrid;
:global SendSignalgrid2;

:set FlushSignalgridQueue do={ :onerror Err {
  :global SignalgridQueue;

  :global IsFullyConnected;
  :global LogPrint;

  :if ([ $IsFullyConnected ] = false) do={
    $LogPrint debug $0 ("System is not fully connected, not flushing.");
    :return false;
  }

  :local AllDone true;
  :local QueueLen [ :len $SignalgridQueue ];

  :if ([ :len [ /system/scheduler/find where name="_FlushSignalgridQueue" ] ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 ("Flushing Signalgrid messages from scheduler, but queue is empty.");
  }

  :foreach Id,Request in=$SignalgridQueue do={
    :if ([ :typeof $Request ] = "array") do={
      :onerror Err {
        /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
          http-header-field=($Request->"headers") \
          http-data=($Request->"data") \
          ($Request->"url") as-value;
        :set ($SignalgridQueue->$Id);
      } do={
        $LogPrint debug $0 ("Sending queued Signalgrid notification failed: " . $Err);
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

:set ($NotificationFunctions->"signalgrid") do={
  :local Notification $1;

  :global Identity;
  :global IdentityExtra;
  :global SignalgridChannel;
  :global SignalgridChannelOverride;
  :global SignalgridClientKey;
  :global SignalgridClientKeyOverride;
  :global SignalgridCritical;
  :global SignalgridCriticalOverride;
  :global SignalgridQueue;

  :global EitherOr;
  :global FetchUserAgentStr;
  :global LogPrint;
  :global SymbolForNotification;

  :local Origin ($Notification->"origin");

  :local ClientKey [ $EitherOr \
    ($SignalgridClientKeyOverride->$Origin) \
    $SignalgridClientKey ];

  :local Channel [ $EitherOr \
    ($SignalgridChannelOverride->$Origin) \
    $SignalgridChannel ];

  :local Critical [ $EitherOr \
    ($SignalgridCriticalOverride->$Origin) \
    $SignalgridCritical ];

  :if ([ :typeof ($Notification->"critical") ] != "nothing") do={
    :set Critical ($Notification->"critical");
  }

  :if ([ :len $ClientKey ] = 0 || [ :len $Channel ] = 0) do={
    :return false;
  }

  :local Title ($Notification->"title");

  :if ([ :typeof $Title ] = "nothing") do={
    :set Title ($Notification->"subject");
  }

  :if ([ :typeof $Title ] = "nothing") do={
    :set Title "";
  }

  :local Body ($Notification->"body");

  :if ([ :typeof $Body ] = "nothing") do={
    :set Body ($Notification->"message");
  }

  :if ([ :typeof $Body ] = "nothing") do={
    :set Body "";
  }

  :local Severity ($Notification->"severity");

  :if ([ :typeof $Severity ] = "nothing") do={
    :set Severity "info";
  }

  :if ([ :len ($Notification->"link") ] > 0) do={
    :set Body ($Body . "\n\n" . \
      [ $SymbolForNotification "link" ] . ($Notification->"link"));
  }

  :if ([ :len $Origin ] > 0) do={
    :set Title ("[" . $IdentityExtra . $Identity . "] " . $Title);
  }

  :local Url "https://api.signalgrid.co/v1/push";

  :local Headers ({
    [ $FetchUserAgentStr $Origin ];
    "Content-Type: application/x-www-form-urlencoded"
  });

  :local Data ("client_key=" . [ :convert $ClientKey to=url ] . \
    "&channel=" . [ :convert $Channel to=url ] . \
    "&title=" . [ :convert $Title to=url ] . \
    "&body=" . [ :convert $Body to=url ] . \
    "&severity=" . [ :convert $Severity to=url ] . \
    "&critical=" . [ :convert [ :tostr $Critical ] to=url ]);

  :onerror Err {
    /tool/fetch check-certificate=yes-without-crl output=none http-method=post \
      http-header-field=$Headers \
      http-data=$Data \
      $Url as-value;
  } do={
    $LogPrint info $0 ("Failed sending Signalgrid notification: " . $Err . " - Queuing...");

    :if ([ :typeof $SignalgridQueue ] = "nothing") do={
      :set SignalgridQueue ({});
    }

    :set Body ($Body . "\n\n" . \
      [ $SymbolForNotification "alarm-clock" ] . \
      "This message was queued since " . \
      [ /system/clock/get date ] . " " . \
      [ /system/clock/get time ] . \
      " and may be obsolete.");

    :set Data ("client_key=" . [ :convert $ClientKey to=url ] . \
      "&channel=" . [ :convert $Channel to=url ] . \
      "&title=" . [ :convert $Title to=url ] . \
      "&body=" . [ :convert $Body to=url ] . \
      "&severity=" . [ :convert $Severity to=url ] . \
      "&critical=" . [ :convert [ :tostr $Critical ] to=url ]);

    :set ($SignalgridQueue->[ :len $SignalgridQueue ]) ({
      url=$Url;
      headers=$Headers;
      data=$Data
    });

    :if ([ :len [ /system/scheduler/find where name="_FlushSignalgridQueue" ] ] = 0) do={
      /system/scheduler/add name="_FlushSignalgridQueue" interval=1m start-time=startup \
        on-event=(":global FlushSignalgridQueue; \$FlushSignalgridQueue;");
    }
  }
}

:set PurgeSignalgridQueue do={
  :global SignalgridQueue;

  /system/scheduler/remove [ find where name="_FlushSignalgridQueue" ];
  :set SignalgridQueue;
}

:set SendSignalgrid do={ :onerror Err {
  :global SendSignalgrid2;

  $SendSignalgrid2 ({
    title=$0;
    body=$1;
    severity=$2;
    critical=$3
  });
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

:set SendSignalgrid2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"signalgrid") \
    ("\$NotificationFunctions->\"signalgrid\"") \
    $Notification;
}
