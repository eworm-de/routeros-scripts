#!rsc by RouterOS
# RouterOS script: log-forward
# Copyright (c) 2020-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# forward log messages via notification
# https://rsc.eworm.de/doc/log-forward.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local ExitOK false;
:do {
  :local ScriptName [ :jobname ];

  :global Identity;
  :global LogForwardFilter;
  :global LogForwardFilterMessage;
  :global LogForwardInclude;
  :global LogForwardIncludeMessage;
  :global LogForwardLast;
  :global LogForwardRateLimit;

  :global EitherOr;
  :global HexToNum;
  :global IfThenElse;
  :global LogForwardFilterLogForwarding;
  :global LogPrint;
  :global MAX;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :if ([ :typeof $LogForwardRateLimit ] = "nothing") do={
    :set LogForwardRateLimit 0;
  }

  :if ($LogForwardRateLimit > 30) do={
    :set LogForwardRateLimit ($LogForwardRateLimit - 1);
    $LogPrint info $ScriptName ("Rate limit in action, not forwarding logs, if any!");
    :set ExitOK true;
    :error false;
  }

  :local Count 0;
  :local Duplicates false;
  :local Last [ $IfThenElse ([ :len $LogForwardLast ] > 0) [ $HexToNum $LogForwardLast ] -1 ];
  :local Messages "";
  :local Warning false;
  :local MessageVal;
  :local MessageDups ({});

  :local LogForwardFilterLogForwardingCached [ $EitherOr [ $LogForwardFilterLogForwarding ] ("\$^") ];
  :foreach Message in=[ /log/find where (!(message="") and \
      !(message~$LogForwardFilterLogForwardingCached) and \
      !(topics~$LogForwardFilter) and !(message~$LogForwardFilterMessage)) or \
      topics~$LogForwardInclude or message~$LogForwardIncludeMessage ] do={
    :set MessageVal [ /log/get $Message ];
    :local Bullet "information";

    :if ($Last < [ $HexToNum ($MessageVal->".id") ]) do={
      :local DupCount ($MessageDups->($MessageVal->"message"));
      :if ($MessageVal->"topics" ~ "(warning)") do={
        :set Warning true;
        :set Bullet "large-orange-circle";
      }
      :if ($MessageVal->"topics" ~ "(emergency|alert|critical|error)") do={
        :set Warning true;
        :set Bullet "large-red-circle";
      }
      :if ($DupCount < 3) do={
        :set Messages ($Messages . "\n" . [ $SymbolForNotification $Bullet ] . \
          $MessageVal->"time" . " " . [ :tostr ($MessageVal->"topics") ] . " " . $MessageVal->"message");
      } else={
        :set Duplicates true;
      }
      :set ($MessageDups->($MessageVal->"message")) ($DupCount + 1);
      :set Count ($Count + 1);
    }
  }

  :if ($Count > 0) do={
    :set LogForwardRateLimit ($LogForwardRateLimit + 10);

    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification [ $IfThenElse ($Warning = true) "warning-sign" "memo" ] ] . \
        "Log Forwarding"); \
      message=("The log on " . $Identity . " contains " . [ $IfThenElse ($Count = 1) "this message" \
        ("these " . $Count . " messages") ] . " after " . [ /system/resource/get uptime ] . " uptime." . \
        [ $IfThenElse ($Duplicates = true) (" Multi-repeated messages have been skipped.") ] . \
        [ $IfThenElse ($LogForwardRateLimit > 30) ("\nRate limit in action, delaying forwarding.") ] . \
        "\n" . $Messages) });
  } else={
    :set LogForwardRateLimit [ $MAX 0 ($LogForwardRateLimit - 1) ];
  }

  :local LogAll [ /log/find ];
  :set LogForwardLast ($LogAll->([ :len $LogAll ] - 1) );
} on-error={
  :global ExitError; $ExitError $ExitOK [ :jobname ];
}
