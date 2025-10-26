#!rsc by RouterOS
# RouterOS script: mod/notification-email
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, email, scheduler
#
# send notifications via e-mail
# https://rsc.eworm.de/doc/mod/notification-email.md

:global EMailGenerateFrom;
:global FlushEmailQueue;
:global LogForwardFilterLogForwarding;
:global NotificationEMailSubject;
:global NotificationFunctions;
:global PurgeEMailQueue;
:global QuotedPrintable;
:global SendEMail;
:global SendEMail2;

# generate from-property with display name
:set EMailGenerateFrom do={
  :global Identity;

  :global CleanName;

  :local From [ /tool/e-mail/get from ];

  :if ($From ~ "<.*>\$") do={
    :return $From;
  }

  :return ([ $CleanName $Identity ] . " via routeros-scripts <" . $From . ">");
}

# flush e-mail queue
:set FlushEmailQueue do={ :onerror Err {
  :global EmailQueue;

  :global EitherOr;
  :global EMailGenerateFrom;
  :global FileExists;
  :global IsDNSResolving;
  :global IsTimeSync;
  :global LogPrint;
  :global RmFile;

  :local AllDone true;
  :local QueueLen [ :len $EmailQueue ];
  :local Scheduler [ /system/scheduler/find where name="_FlushEmailQueue" ];

  :if ([ :len $Scheduler ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 ("Flushing E-Mail messages from scheduler, but queue is empty.");
    /system/scheduler/remove $Scheduler;
    :return false;
  }

  :if ($QueueLen = 0) do={
    :return true;
  }

  :if ([ :len $Scheduler ] < 0) do={
    /system/scheduler/add name="_FlushEmailQueue" interval=1m start-time=startup \
        comment="Doing initial checks..." on-event=(":global FlushEmailQueue; \$FlushEmailQueue;");
    :set Scheduler [ /system/scheduler/find where name="_FlushEmailQueue" ];
  }

  :local SchedVal [ /system/scheduler/get $Scheduler ];
  :if (($SchedVal->"interval") < 1m) do={
    /system/scheduler/set interval=1m comment="Doing initial checks..." $Scheduler;
  }

  :if ([ /tool/e-mail/get last-status ] = "in-progress") do={
    $LogPrint debug $0 ("Sending mail is currently in progress, not flushing.");
    :return false;
  }

  :if ([ $IsTimeSync ] = false) do={
    $LogPrint debug $0 ("Time is not synced, not flushing.");
    :return false;
  }

  :local EMailSettings [ /tool/e-mail/get ];
  :if ([ :typeof [ :toip ($EMailSettings->"server") ] ] != "ip" && [ $IsDNSResolving ] = false) do={
    $LogPrint debug $0 ("Server address is a DNS name and resolving fails, not flushing.");
    :return false;
  }

  /system/scheduler/set interval=($QueueLen . "m") comment="Sending..." $Scheduler;

  :foreach Id,Message in=$EmailQueue do={
    :if ([ :typeof $Message ] = "array" ) do={
      :while ([ /tool/e-mail/get last-status ] = "in-progress") do={ :delay 1s; }
      :onerror Err {
        :local Attach ({});
        :foreach File in=[ :toarray [ $EitherOr ($Message->"attach") "" ] ] do={
          :if ([ $FileExists $File ] = true) do={
            :set Attach ($Attach, $File);
          } else={
            $LogPrint warning $0 ("File '" . $File . "' does not exist, can not attach.");
          }
        }
        :do {
          /tool/e-mail/send from=[ $EMailGenerateFrom ] to=($Message->"to") \
              cc=($Message->"cc") subject=($Message->"subject") \
              body=($Message->"body") file=$Attach;
        } on-error={ }
        :local Wait true;
        :do {
          :delay 1s;
          :local Status [ /tool/e-mail/get last-status ];
          :if ($Status = "succeeded") do={
            :set ($EmailQueue->$Id);
            :set Wait false;
            :if (($Message->"remove-attach") = true) do={
              :foreach File in=$Attach do={
                $RmFile $File;
              }
            }
          }
          :if ($Status = "failed") do={
            :set AllDone false;
            :set Wait false;
          }
        } while=($Wait = true);
      } do={
        $LogPrint warning $0 ("Sending queued mail failed: " . $Err);
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $EmailQueue ]) do={
    /system/scheduler/remove $Scheduler;
    :set EmailQueue;
    :return true;
  }

  :if ([ :len [ /system/scheduler/find where name="_FlushEmailQueue" ] ] = 0 && \
       [ :typeof $EmailQueue ] = "nothing") do={
    $LogPrint info $0 ("Queue was purged? Exiting.");
    :return false;
  }

  /system/scheduler/set interval=(($SchedVal->"run-count") . "m") \
      comment="Waiting for retry..." $Scheduler;
} do={
  :global ExitError; $ExitError false $0 $Err;
} }

# generate filter for log-forward
:set LogForwardFilterLogForwarding do={
  :global EscapeForRegEx;
  :global NotificationEMailSubject;
  :global SymbolForNotification;

  :return ("^Error sending e-mail <(" . \
    [ $EscapeForRegEx [ $NotificationEMailSubject ([ $SymbolForNotification \
      "memo" ] . "Log Forwarding") ] ] . "|" . \
    [ $EscapeForRegEx [ $NotificationEMailSubject ([ $SymbolForNotification \
      "warning-sign" ] . "Log Forwarding") ] ] . ")>:");
}

# generate the e-mail subject
:set NotificationEMailSubject do={
  :global Identity;
  :global IdentityExtra;

  :global QuotedPrintable;

  :return [ $QuotedPrintable ("[" . $IdentityExtra . $Identity . "] " . $1) ];
}

# send notification via e-mail - expects one array argument
:set ($NotificationFunctions->"email") do={
  :local Notification $1;

  :global EmailGeneralTo;
  :global EmailGeneralToOverride;
  :global EmailGeneralCc;
  :global EmailGeneralCcOverride;
  :global EmailQueue;

  :global EitherOr;
  :global IfThenElse;
  :global NotificationEMailSignature;
  :global NotificationEMailSubject;
  :global SymbolForNotification;

  :local To [ $EitherOr ($EmailGeneralToOverride->($Notification->"origin")) $EmailGeneralTo ];
  :local Cc [ $EitherOr ($EmailGeneralCcOverride->($Notification->"origin")) $EmailGeneralCc ];

  :local EMailSettings [ /tool/e-mail/get ];
  :if ([ :len $To ] = 0 || ($EMailSettings->"server") = "0.0.0.0" || ($EMailSettings->"from") = "<>") do={
    :return false;
  }

  :if ([ :typeof $EmailQueue ] = "nothing") do={
      :set EmailQueue ({});
  }
  :local Truncated false;
  :local Body ($Notification->"message");
  :if ([ :len $Body ] > 62000) do={
    :set Body ([ :pick $Body 0 62000 ] . "...");
    :set Truncated true;
  }
  :local Signature [ $EitherOr [ $NotificationEMailSignature ] [ /system/note/get note ] ];
  :set Body ($Body . "\n" . \
      [ $IfThenElse ([ :len ($Notification->"link") ] > 0) \
          ("\n" . [ $SymbolForNotification "link" ] . ($Notification->"link")) ] . \
      [ $IfThenElse ($Truncated = true) ("\n" . [ $SymbolForNotification "scissors" ] . \
          "The message was too long and has been truncated!") ] . \
      [ $IfThenElse ([ :len $Signature ] > 0) ("\n-- \n" . $Signature) "" ]);
  :set ($EmailQueue->[ :len $EmailQueue ]) {
    to=$To; cc=$Cc;
    subject=[ $NotificationEMailSubject ($Notification->"subject") ];
    body=$Body; \
    attach=($Notification->"attach"); remove-attach=($Notification->"remove-attach") };
  :if ([ :len [ /system/scheduler/find where name="_FlushEmailQueue" ] ] = 0) do={
    /system/scheduler/add name="_FlushEmailQueue" interval=1s start-time=startup \
      comment="Queuing new mail..." on-event=(":global FlushEmailQueue; \$FlushEmailQueue;");
  }
}

# purge the e-mail queue
:set PurgeEMailQueue do={
  :global EmailQueue;

  /system/scheduler/remove [ find where name="_FlushEmailQueue" ];
  :set EmailQueue;
}

# convert string to quoted-printable
:global QuotedPrintable do={
  :local Input [ :tostr $1 ];

  :global CharacterMultiply;

  :if ([ :len $Input ] = 0) do={
    :return $Input;
  }

  :local Return "";
  :local Chars ( \
    "\00\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F" . \
    [ $CharacterMultiply ("\00") 29 ] . "=\00?" . [ $CharacterMultiply ("\00") 63 ] . "\7F" . \
    "\80\81\82\83\84\85\86\87\88\89\8A\8B\8C\8D\8E\8F\90\91\92\93\94\95\96\97\98\99\9A\9B\9C\9D\9E\9F" . \
    "\A0\A1\A2\A3\A4\A5\A6\A7\A8\A9\AA\AB\AC\AD\AE\AF\B0\B1\B2\B3\B4\B5\B6\B7\B8\B9\BA\BB\BC\BD\BE\BF" . \
    "\C0\C1\C2\C3\C4\C5\C6\C7\C8\C9\CA\CB\CC\CD\CE\CF\D0\D1\D2\D3\D4\D5\D6\D7\D8\D9\DA\DB\DC\DD\DE\DF" . \
    "\E0\E1\E2\E3\E4\E5\E6\E7\E8\E9\EA\EB\EC\ED\EE\EF\F0\F1\F2\F3\F4\F5\F6\F7\F8\F9\FA\FB\FC\FD\FE\FF");
  :local Hex "0123456789ABCDEF";

  :for I from=0 to=([ :len $Input ] - 1) do={
    :local Char [ :pick $Input $I ];
    :local Replace [ :find $Chars $Char ];

    :if ([ :typeof $Replace ] = "num") do={
      :set Char ("=" . [ :pick $Hex ($Replace / 16)] . [ :pick $Hex ($Replace % 16) ]);
    }
    :set Return ($Return . $Char);
  }

  :if ($Input = $Return) do={
    :return $Input;
  }

  :return ("=?utf-8?Q?" . $Return . "?=");
}

# send notification via e-mail - expects at least two string arguments
:set SendEMail do={ :onerror Err {
  :global SendEMail2;

  $SendEMail2 ({ origin=$0; subject=$1; message=$2; link=$3 });
} do={
  :global ExitError; $ExitError false $0 $Err;
} }

# send notification via e-mail - expects one array argument
:set SendEMail2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"email") ("\$NotificationFunctions->\"email\"") $Notification;
}
