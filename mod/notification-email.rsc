#!rsc by RouterOS
# RouterOS script: mod/notification-email
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# send notifications via e-mail
# https://git.eworm.de/cgit/routeros-scripts/about/doc/mod/notification-email.md

:global FlushEmailQueue;
:global LogForwardFilterLogForwarding;
:global NotificationEMailSubject;
:global NotificationFunctions;
:global QuotedPrintable;
:global SendEMail;
:global SendEMail2;

# flush e-mail queue
:set FlushEmailQueue do={
  :global EmailQueue;

  :global EitherOr;
  :global IsDNSResolving;
  :global IsTimeSync;
  :global LogPrintExit2;

  :local AllDone true;
  :local QueueLen [ :len $EmailQueue ];
  :local Scheduler [ /system/scheduler/find where name=$0 ];
  
  :if ([ :len $Scheduler ] > 0 && [ /system/scheduler/get $Scheduler interval ] < 1m) do={
    /system/scheduler/set interval=1m comment="Doing initial checks..." $Scheduler;
  }

  :if ([ /tool/e-mail/get last-status ] = "in-progress") do={
    $LogPrintExit2 debug $0 ("Sending mail is currently in progress, not flushing.") false;
    :return false;
  }

  :if ([ $IsTimeSync ] = false) do={
    $LogPrintExit2 debug $0 ("Time is not synced, not flushing.") false;
    :return false;
  }

  :if ([ :typeof [ :toip [ /tool/e-mail/get address ] ] ] != "ip" && [ $IsDNSResolving ] = false) do={
    $LogPrintExit2 debug $0 ("Server address is a DNS name and resolving fails, not flushing.") false;
    :return false;
  }

  :if ([ :len $Scheduler ] > 0 && $QueueLen = 0) do={
    $LogPrintExit2 warning $0 ("Flushing E-Mail messages from scheduler, but queue is empty.") false;
  }

  /system/scheduler/set interval=([ $EitherOr $QueueLen 1 ] . "m") comment="Sending..." $Scheduler;

  :foreach Id,Message in=$EmailQueue do={
    :if ([ :typeof $Message ] = "array" ) do={
      :local Attach ({});
      :while ([ /tool/e-mail/get last-status ] = "in-progress") do={ :delay 1s; }
      :foreach File in=[ :toarray [ $EitherOr ($Message->"attach") "" ] ] do={
        :if ([ :len [ /file/find where name=$File ] ] = 1) do={
          :set Attach ($Attach, $File);
        } else={
          $LogPrintExit2 warning $0 ("File '" . $File . "' does not exist, can not attach.") false;
        }
      }
      /tool/e-mail/send to=($Message->"to") cc=($Message->"cc") subject=($Message->"subject") \
        body=($Message->"body") file=$Attach;
      :local Wait true;
      :do {
        :delay 1s;
        :local Status [ /tool/e-mail/get last-status ];
        :if ($Status = "succeeded") do={
          :set ($EmailQueue->$Id);
          :set Wait false;
          :if (($Message->"remove-attach") = true) do={
            :foreach File in=$Attach do={
              /file/remove $File;
            }
          }
        }
        :if ($Status = "failed") do={
          :set AllDone false;
          :set Wait false;
        }
      } while=($Wait = true);
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $EmailQueue ]) do={
    /system/scheduler/remove $Scheduler;
    :set EmailQueue;
  } else={
    /system/scheduler/set interval=1m comment="Waiting for retry..." $Scheduler;
  }
}

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
  :global NotificationEMailSubject;

  :local To [ $EitherOr ($EmailGeneralToOverride->($Notification->"origin")) $EmailGeneralTo ];
  :local Cc [ $EitherOr ($EmailGeneralCcOverride->($Notification->"origin")) $EmailGeneralCc ];

  :local EMailSettings [ /tool/e-mail/get ];
  :if ([ :len $To ] = 0 || ($EMailSettings->"address") = "0.0.0.0" || ($EMailSettings->"from") = "<>") do={
    :return false;
  }

  :if ([ :typeof $EmailQueue ] = "nothing") do={
      :set EmailQueue ({});
  }
  :local Signature [ /system/note/get note ];
  :set ($EmailQueue->[ :len $EmailQueue ]) {
    to=$To; cc=$Cc;
    subject=[ $NotificationEMailSubject ($Notification->"subject") ];
    body=(($Notification->"message") . \
      [ $IfThenElse ([ :len ($Notification->"link") ] > 0) ("\n\n" . ($Notification->"link")) "" ] . \
      [ $IfThenElse ([ :len $Signature ] > 0) ("\n-- \n" . $Signature) "" ]); \
    attach=($Notification->"attach"); remove-attach=($Notification->"remove-attach") };
  :if ([ :len [ /system/scheduler/find where name="\$FlushEmailQueue" ] ] = 0) do={
    /system/scheduler/add name="\$FlushEmailQueue" interval=1s start-time=startup \
      comment="Queuing new mail..." on-event=(":global FlushEmailQueue; \$FlushEmailQueue;");
  }
}

# convert string to quoted-printable
:global QuotedPrintable do={
  :local Input [ :tostr $1 ];

  :if ([ :len $Input ] = 0) do={
    :return $Input;
  }

  :local Return "";
  :local Chars ("\80\81\82\83\84\85\86\87\88\89\8A\8B\8C\8D\8E\8F\90\91\92\93\94\95\96\97" . \
    "\98\99\9A\9B\9C\9D\9E\9F\A0\A1\A2\A3\A4\A5\A6\A7\A8\A9\AA\AB\AC\AD\AE\AF\B0\B1\B2\B3" . \
    "\B4\B5\B6\B7\B8\B9\BA\BB\BC\BD\BE\BF\C0\C1\C2\C3\C4\C5\C6\C7\C8\C9\CA\CB\CC\CD\CE\CF" . \
    "\D0\D1\D2\D3\D4\D5\D6\D7\D8\D9\DA\DB\DC\DD\DE\DF\E0\E1\E2\E3\E4\E5\E6\E7\E8\E9\EA\EB" . \
    "\EC\ED\EE\EF\F0\F1\F2\F3\F4\F5\F6\F7\F8\F9\FA\FB\FC\FD\FE\FF");
  :local Hex { "0"; "1"; "2"; "3"; "4"; "5"; "6"; "7"; "8"; "9"; "A"; "B"; "C"; "D"; "E"; "F" };

  :for I from=0 to=([ :len $Input ] - 1) do={
    :local Char [ :pick $Input $I ];
    :local Replace [ :find $Chars $Char ];

    :if ($Char = "=") do={
      :set Char "=3D";
    }
    :if ([ :typeof $Replace ] = "num") do={
      :set Char ("=" . ($Hex->($Replace / 16 + 8)) . ($Hex->($Replace % 16)));
    }
    :set Return ($Return . $Char);
  }

  :if ($Input = $Return) do={
    :return $Input;
  }

  :return ("=?utf-8?Q?" . $Return . "?=");
}

# send notification via e-mail - expects at least two string arguments
:set SendEMail do={
  :global SendEMail2;

  $SendEMail2 ({ subject=$1; message=$2; link=$3 });
}

# send notification via e-mail - expects one array argument
:set SendEMail2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"email") ("\$NotificationFunctions->\"email\"") $Notification;
}
