#!rsc by RouterOS
# RouterOS script: mod/notification-email
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, email, scheduler
#
# send notifications via e-mail
# https://rsc.eworm.de/doc/mod/notification-email.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=notification-email, schema=5a6236090c5b7c3f80f50b70e58e9489c8100e4505c9ddc4ee72854e4de47c20
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"notification-email.attach.missing") "File '{file}' does not exist, can not attach.";
:set ($LanguageEnglish->"notification-email.certificate.failed") "Downloading required certificate failed.";
:set ($LanguageEnglish->"notification-email.checking") "Doing initial checks...";
:set ($LanguageEnglish->"notification-email.dns.failed") "Server address is a DNS name and resolving fails, not flushing.";
:set ($LanguageEnglish->"notification-email.from") "{identity} via routeros-scripts <{address}>";
:set ($LanguageEnglish->"notification-email.queue.empty") "Flushing E-Mail messages from scheduler, but queue is empty.";
:set ($LanguageEnglish->"notification-email.queue.purged") "Queue was purged? Exiting.";
:set ($LanguageEnglish->"notification-email.queuing") "Queuing new mail...";
:set ($LanguageEnglish->"notification-email.retry.waiting") "Waiting for retry...";
:set ($LanguageEnglish->"notification-email.scheduler.gone") "The scheduler is gone, aborting.";
:set ($LanguageEnglish->"notification-email.send.failed") "Sending queued mail failed: {error}";
:set ($LanguageEnglish->"notification-email.sending") "Sending...";
:set ($LanguageEnglish->"notification-email.sending.busy") "Sending mail is currently in progress, not flushing.";
:set ($LanguageEnglish->"notification-email.time.unsynced") "Time is not synced, not flushing.";
:set ($LanguageEnglish->"notification-email.truncated") "The message was too long and has been truncated!";
# END GENERATED LANGUAGE DATA

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
  :global Translate;

  :local From [ /tool/e-mail/get from ];

  :if ($From ~ "<.*>\$") do={
    :return $From;
  }

  :return [ $Translate "notification-email.from" \
      ({ identity=[ $CleanName $Identity ]; address=$From }) ];
}

# flush e-mail queue
:set FlushEmailQueue do={ :onerror Err {
  :global EmailQueue;
  :global EmailServerCertificate;

  :global CertificateAvailable;
  :global EitherOr;
  :global EMailGenerateFrom;
  :global FileExists;
  :global IsDNSResolving;
  :global IsTimeSync;
  :global LogPrint;
  :global Translate;
  :global RmFile;

  :local AllDone true;
  :local QueueLen [ :len $EmailQueue ];

  :if ([ :len [ /system/scheduler/find where name="_FlushEmailQueue" ] ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 [ $Translate "notification-email.queue.empty" ];
    /system/scheduler/remove [ find where name="_FlushEmailQueue" ];
    :return false;
  }

  :if ($QueueLen = 0) do={
    :return true;
  }

  :if ([ :len [ /system/scheduler/find where name="_FlushEmailQueue" ] ] < 0) do={
    /system/scheduler/add name="_FlushEmailQueue" interval=1m start-time=startup \
        comment=[ $Translate "notification-email.checking" ] on-event=(":global FlushEmailQueue; \$FlushEmailQueue;");
  }

  :do {
    :if (([ /system/scheduler/get [ find where name="_FlushEmailQueue" ] ]->"interval") < 1m) do={
      /system/scheduler/set interval=1m comment=[ $Translate "notification-email.checking" ] \
        [ find where name="_FlushEmailQueue" ];
    } 
  } on-error={
    $LogPrint debug $0 [ $Translate "notification-email.scheduler.gone" ];
    :return false;
  }

  :if ([ /tool/e-mail/get last-status ] = "in-progress") do={
    $LogPrint debug $0 [ $Translate "notification-email.sending.busy" ];
    :return false;
  }

  :if ([ $IsTimeSync ] = false) do={
    $LogPrint debug $0 [ $Translate "notification-email.time.unsynced" ];
    :return false;
  }

  :local EMailSettings [ /tool/e-mail/get ];
  :if ([ :typeof [ :toip ($EMailSettings->"server") ] ] != "ip" && [ $IsDNSResolving ] = false) do={
    $LogPrint debug $0 [ $Translate "notification-email.dns.failed" ];
    :return false;
  }

  :if ([ /tool/e-mail/get certificate-verification ] ~ "^yes" && \
       [ :len $EmailServerCertificate ] > 0) do={
    :if ([ $CertificateAvailable $EmailServerCertificate "email" ] = false) do={
      $LogPrint warning $0 [ $Translate "notification-email.certificate.failed" ];
      :return false;
    }
  }

  /system/scheduler/set interval=($QueueLen . "m") comment=[ $Translate "notification-email.sending" ] \
    [ find where name="_FlushEmailQueue" ];

  :foreach Id,Message in=$EmailQueue do={
    :if ([ :typeof $Message ] = "array" ) do={
      :onerror Err {
        :local Attach ({});
        :foreach File in=[ :toarray [ $EitherOr ($Message->"attach") "" ] ] do={
          :if ([ $FileExists $File ] = true) do={
            :set Attach ($Attach, $File);
          } else={
            $LogPrint warning $0 [ $Translate "notification-email.attach.missing" \
                ({ file=$File }) ];
          }
        }
        /tool/e-mail/send from=[ $EMailGenerateFrom ] to=($Message->"to") \
            cc=($Message->"cc") subject=($Message->"subject") \
            body=($Message->"body") file=$Attach;
        :set ($EmailQueue->$Id);
        :if (($Message->"remove-attach") = true) do={
          :foreach File in=$Attach do={
            $RmFile $File;
          }
        }
      } do={
        $LogPrint warning $0 [ $Translate "notification-email.send.failed" \
            ({ error=$Err }) ];
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $EmailQueue ]) do={
    /system/scheduler/remove [ find where name="_FlushEmailQueue" ];
    :set EmailQueue;
    :return true;
  }

  :if ([ :len [ /system/scheduler/find where name="_FlushEmailQueue" ] ] = 0 && \
       [ :typeof $EmailQueue ] = "nothing") do={
    $LogPrint info $0 [ $Translate "notification-email.queue.purged" ];
    :return false;
  }

  /system/scheduler/set interval=(([ get [ find where name="_FlushEmailQueue" ] ]->"run-count") . "m") \
      comment=[ $Translate "notification-email.retry.waiting" ] [ find where name="_FlushEmailQueue" ];
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# generate filter for log-forward
:set LogForwardFilterLogForwarding do={
  :global EscapeForRegEx;
  :global LogForwardFilterSubjects;
  :global NotificationEMailSubject;
  :global SymbolForNotification;

  # Remember subjects already used so a language change cannot forward old
  # delivery failures again. The native RouterOS error prefix stays unchanged.
  :if ([ :typeof $LogForwardFilterSubjects ] != "array") do={
    :set LogForwardFilterSubjects ({});
  }
  :set ($LogForwardFilterSubjects->"Log Forwarding") true;
  :if ([ :len $1 ] > 0) do={ :set ($LogForwardFilterSubjects->$1) true; }
  :local Patterns "";
  :foreach Subject,Unused in=$LogForwardFilterSubjects do={
    :foreach Symbol in={ "memo"; "warning-sign" } do={
      :if ([ :len $Patterns ] > 0) do={ :set Patterns ($Patterns . "|"); }
      :set Patterns ($Patterns . [ $EscapeForRegEx [ $NotificationEMailSubject \
          ([ $SymbolForNotification $Symbol ] . $Subject) ] ]);
    }
  }
  :return ("^Error sending e-mail <(" . $Patterns . ")>:");
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
  :global Translate;
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
          [ $Translate "notification-email.truncated" ]) ] . \
      [ $IfThenElse ([ :len $Signature ] > 0) ("\n-- \n" . $Signature) "" ]);
  :set ($EmailQueue->[ :len $EmailQueue ]) {
    to=$To; cc=$Cc;
    subject=[ $NotificationEMailSubject ($Notification->"subject") ];
    body=$Body; \
    attach=($Notification->"attach"); remove-attach=($Notification->"remove-attach") };
  :if ([ :len [ /system/scheduler/find where name="_FlushEmailQueue" ] ] = 0) do={
    /system/scheduler/add name="_FlushEmailQueue" interval=1s start-time=startup \
      comment=[ $Translate "notification-email.queuing" ] on-event=(":global FlushEmailQueue; \$FlushEmailQueue;");
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
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# send notification via e-mail - expects one array argument
:set SendEMail2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"email") ("\$NotificationFunctions->\"email\"") $Notification;
}
