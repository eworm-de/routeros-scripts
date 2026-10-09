#!rsc by RouterOS
# RouterOS script: log-forward
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# forward log messages via notification
# https://rsc.eworm.de/doc/log-forward.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=log-forward, schema=295a2441ccf8e06593a7eedcf16e2ac316badd8c4111d4dab8823ac3b329473c
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"log-forward.delaying") "\0ARate limit in action, delaying forwarding.";
:set ($LanguageEnglish->"log-forward.duplicates") " Multi-repeated messages have been skipped.";
:set ($LanguageEnglish->"log-forward.limited") "Rate limit in action, not forwarding logs, if any!";
:set ($LanguageEnglish->"log-forward.message.multiple") "The log on {identity} contains these {count} messages after {uptime} uptime.{duplicates}{delay}\0A{messages}";
:set ($LanguageEnglish->"log-forward.message.single") "The log on {identity} contains this message after {uptime} uptime.{duplicates}{delay}\0A{messages}";
:set ($LanguageEnglish->"log-forward.subject") "Log Forwarding";
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global Identity;
  :global LogForwardFilter;
  :global LogForwardFilterMessage;
  :global LogForwardInclude;
  :global LogForwardIncludeMessage;
  :global LogForwardLast;
  :global LogForwardRateLimit;

  :global EitherOr;
  :global IfThenElse;
  :global LogForwardFilterLogForwarding;
  :global LogPrint;
  :global Translate;
  :global MAX;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :if ([ :typeof $LogForwardLast ] = "nothing") do={
    :set LogForwardLast false;
  }

  :if ([ :typeof $LogForwardRateLimit ] = "nothing") do={
    :set LogForwardRateLimit 0;
  }

  :if ($LogForwardRateLimit > 30) do={
    :set LogForwardRateLimit ($LogForwardRateLimit - 1);
    $LogPrint info $ScriptName [ $Translate "log-forward.limited" ];
    :exit;
  }

  :local Count 0;
  :local Duplicates false;
  :local Messages "";
  :local Warning false;
  :local MessageVal;
  :local MessageDups ({});

  :set LogForwardFilter [ $EitherOr $LogForwardFilter [] ];
  :set LogForwardFilterMessage [ $EitherOr $LogForwardFilterMessage [] ];
  :set LogForwardInclude [ $EitherOr $LogForwardInclude [] ];
  :set LogForwardIncludeMessage [ $EitherOr $LogForwardIncludeMessage [] ];

  :local LogAll [ /log/find ];
  :local Max ($LogAll->([ :len $LogAll ] - 1));
  :local Subject [ $Translate "log-forward.subject" ];
  :local LogForwardFilterLogForwardingCached [ $EitherOr [ $LogForwardFilterLogForwarding $Subject ] ("\$^") ];

  :foreach Message in=[ /log/find where .id>$LogForwardLast and .id<=$Max and \
      ((!(message="") and !(message~$LogForwardFilterLogForwardingCached) and \
        !(topics~$LogForwardFilter) and !(message~$LogForwardFilterMessage)) or \
       topics~$LogForwardInclude or message~$LogForwardIncludeMessage) ] do={
    :set MessageVal [ /log/get $Message ];
    :local Bullet "information";

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

  :if ($Count > 0) do={
    :set LogForwardRateLimit ($LogForwardRateLimit + 10);

    :local DuplicateNotice "";
    :local DelayNotice "";
    :if ($Duplicates = true) do={ :set DuplicateNotice [ $Translate "log-forward.duplicates" ]; }
    :if ($LogForwardRateLimit > 30) do={ :set DelayNotice [ $Translate "log-forward.delaying" ]; }
    :local Summary [ $Translate "log-forward.message.multiple" \
        ({ identity=$Identity; count=$Count; uptime=[ /system/resource/get uptime ]; \
        duplicates=$DuplicateNotice; delay=$DelayNotice; messages=$Messages }) ];
    :if ($Count = 1) do={
      :set Summary [ $Translate "log-forward.message.single" \
          ({ identity=$Identity; uptime=[ /system/resource/get uptime ]; \
          duplicates=$DuplicateNotice; delay=$DelayNotice; messages=$Messages }) ];
    }

    $SendNotification2 ({ origin=$ScriptName; \
      subject=([ $SymbolForNotification ("memo" . [ $IfThenElse ($Warning = true) ",warning-sign" ]) ] . \
        $Subject); \
      message=$Summary });
  } else={
    :set LogForwardRateLimit [ $MAX 0 ($LogForwardRateLimit - 1) ];
  }

  :set LogForwardLast $Max;
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
