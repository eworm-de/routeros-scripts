#!rsc by RouterOS
# RouterOS script: mod/notification-telegram
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
# requires device-mode, fetch, scheduler
#
# send notifications via Telegram
# https://rsc.eworm.de/doc/mod/notification-telegram.md

:global FlushTelegramQueue;
:global GetTelegramChatId;
:global NotificationFunctions;
:global PurgeTelegramQueue;
:global SendTelegram;
:global SendTelegram2;

# flush telegram queue
:set FlushTelegramQueue do={ :onerror Err {
  :global TelegramQueue;
  :global TelegramMessageIDs;

  :global CertificateAvailable;
  :global IsFullyConnected;
  :global LogPrint;

  :if ([ $IsFullyConnected ] = false) do={
    $LogPrint debug $0 ("System is not fully connected, not flushing.");
    :return false;
  }

  :if ([ $CertificateAvailable "Go Daddy Root Certificate Authority - G2" ] = false) do={
    $LogPrint warning $0 ("Downloading required certificate failed.");
    :return false;
  }

  :local AllDone true;
  :local QueueLen [ :len $TelegramQueue ];

  :if ([ :len [ /system/scheduler/find where name="_FlushTelegramQueue" ] ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 ("Flushing Telegram messages from scheduler, but queue is empty.");
  }

  :foreach Id,Message in=$TelegramQueue do={
    :if ([ :typeof $Message ] = "array" ) do={
      :onerror Err {
        :local Data ([ /tool/fetch check-certificate=yes-without-crl output=user http-method=post \
          ("https://api.telegram.org/bot" . ($Message->"tokenid") . "/sendMessage") \
          http-data=($Message->"http-data") as-value ]->"data");
        :set ($TelegramQueue->$Id);
        :set ($TelegramMessageIDs->[ :tostr ([ :deserialize from=json value=$Data ]->"result"->"message_id") ]) 1;
      } do={
        $LogPrint debug $0 ("Sending queued Telegram message failed: " . $Err);
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $TelegramQueue ]) do={
    /system/scheduler/remove [ find where name="_FlushTelegramQueue" ];
    :set TelegramQueue;
  }
} do={
  :global ExitError; $ExitError false $0 $Err;
} }

# get the chat id
:set GetTelegramChatId do={ :onerror Err {
  :global TelegramTokenId;

  :global CertificateAvailable;
  :global LogPrint;

  :if ([ $CertificateAvailable "Go Daddy Root Certificate Authority - G2" ] = false) do={
    $LogPrint warning $0 ("Downloading required certificate failed.");
    :return false;
  }

  :local Data;
  :onerror Err {
    :set Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
       ("https://api.telegram.org/bot" . $TelegramTokenId . "/getUpdates?offset=0" . \
       "&allowed_updates=%5B%22message%22%5D") as-value ]->"data");
  } do={
    $LogPrint warning $0 ("Fetching data failed: " . $Err);
    :return false;
  }

  :local JSON [ :deserialize from=json value=$Data ];
  :local Count [ :len ($JSON->"result") ];

  :if ($Count = 0) do={
    $LogPrint info $0 ("No message received.");
    :return false;
  }

  :local Message ($JSON->"result"->($Count - 1)->"message");
  $LogPrint info $0 ("The chat id is: " . ($Message->"chat"->"id"));
  :if (($Message->"is_topic_message") = true) do={
    $LogPrint info $0 ("The thread id is: " . ($Message->"message_thread_id"));
  }
} do={
  :global ExitError; $ExitError false $0 $Err;
} } 

# send notification via telegram - expects one array argument
:set ($NotificationFunctions->"telegram") do={
  :local Notification $1;

  :global Identity;
  :global IdentityExtra;
  :global TelegramChatId;
  :global TelegramChatIdOverride;
  :global TelegramMessageIDs;
  :global TelegramQueue;
  :global TelegramThreadId;
  :global TelegramThreadIdOverride;
  :global TelegramTokenId;
  :global TelegramTokenIdOverride;

  :global CertificateAvailable;
  :global CharacterReplace;
  :global EitherOr;
  :global IfThenElse;
  :global LogPrint;
  :global ProtocolStrip;
  :global SymbolForNotification;
  :global UrlEncode;

  :local EscapeMD do={
    :local Text [ :tostr $1 ];
    :local Mode [ :tostr $2 ];
    :local Excl [ :tostr $3 ];

    :global CharacterReplace;
    :global IfThenElse;

    :local Chars {
       "body"={ "\\"; "`" };
      "plain"={ "_"; "*"; "["; "]"; "("; ")"; "~"; "`"; ">";
                "#"; "+"; "-"; "="; "|"; "{"; "}"; "."; "!" };
    }
    :foreach Char in=($Chars->$Mode) do={
      :if ([ :typeof [ :find $Excl $Char ] ] = "nil") do={
        :set Text [ $CharacterReplace $Text $Char ("\\" . $Char) ];
      }
    }

    :if ($Mode = "body") do={
      :return ("```\n" . $Text . "\n```");
    }

    :return $Text;
  }

  :local ChatId [ $EitherOr ($Notification->"chatid") \
    [ $EitherOr ($TelegramChatIdOverride->($Notification->"origin")) $TelegramChatId ] ];
  :local ThreadId [ $EitherOr ($Notification->"threadid") \
    [ $EitherOr ($TelegramThreadIdOverride->($Notification->"origin")) \
    [ $IfThenElse ([ :len ($TelegramChatIdOverride->($Notification->"origin")) ] = 0) $TelegramThreadId ] ] ];
  :local TokenId [ $EitherOr ($TelegramTokenIdOverride->($Notification->"origin")) $TelegramTokenId ];

  :if ([ :len $TokenId ] = 0 || [ :len $ChatId ] = 0) do={
    :return false;
  }

  :if ([ :typeof $TelegramMessageIDs ] = "nothing") do={
    :set TelegramMessageIDs ({});
  }

  :local Truncated false;
  :local Text ("*__" . [ $EscapeMD ("[" . $IdentityExtra . $Identity . "] " . \
    ($Notification->"subject")) "plain" ] . "__*\n\n");
  :local LenSubject [ :len $Text ];
  :local LenMessage [ :len ($Notification->"message") ];
  :local LenLink ([ :len ($Notification->"link") ] * 2);
  :local LenSum ($LenSubject + $LenMessage + $LenLink);
  :if ($LenSum > 3968) do={
    :set Text ($Text . [ $EscapeMD ([ :pick ($Notification->"message") 0 (3840 - $LenSubject - $LenLink) ] . "...") "body" ]);
    :set Truncated true;
  } else={
    :set Text ($Text . [ $EscapeMD ($Notification->"message") "body" ]);
  }
  :if ($LenLink > 0) do={
    :set Text ($Text . "\n" . [ $SymbolForNotification "link" ] . \
      "[" . [ $EscapeMD [ $ProtocolStrip ($Notification->"link") ] "plain" ] . "]" . \
      "(" . [ $EscapeMD ($Notification->"link") "plain" ] . ")");
  }
  :if ($Truncated = true) do={
    :set Text ($Text . "\n" . [ $SymbolForNotification "scissors" ] . \
      [ $EscapeMD ("The message was too long and has been truncated, cut off _" . \
      (($LenSum - [ :len $Text ]) * 100 / $LenSum) . "%_!") "plain" "_" ]);
  }

  :local HTTPData ("chat_id=" . $ChatId . "&disable_notification=" . ($Notification->"silent") . \
      "&reply_to_message_id=" . ($Notification->"replyto") . "&message_thread_id=" . $ThreadId . \
      "&disable_web_page_preview=true&parse_mode=MarkdownV2");
  :onerror Err {
    :if ([ $CertificateAvailable "Go Daddy Root Certificate Authority - G2" ] = false) do={
      $LogPrint warning $0 ("Downloading required certificate failed.");
      :error false;
    }
    :local Data ([ /tool/fetch check-certificate=yes-without-crl output=user http-method=post \
      ("https://api.telegram.org/bot" . $TokenId . "/sendMessage") \
      http-data=($HTTPData . "&text=" . [ $UrlEncode $Text ]) as-value ]->"data");
    :set ($TelegramMessageIDs->[ :tostr ([ :deserialize from=json value=$Data ]->"result"->"message_id") ]) 1;
  } do={
    $LogPrint info $0 ("Failed sending Telegram notification: " . $Err . " - Queuing...");

    :if ([ :typeof $TelegramQueue ] = "nothing") do={
      :set TelegramQueue ({});
    }
    :set Text ($Text . "\n" . [ $SymbolForNotification "alarm-clock" ] . \
      [ $EscapeMD ("This message was queued since _" . [ /system/clock/get date ] . \
      " " . [ /system/clock/get time ] . "_ and may be obsolete.") "plain" "_" ]);
    :set ($TelegramQueue->[ :len $TelegramQueue ]) { tokenid=$TokenId;
      http-data=($HTTPData . "&text=" . [ $UrlEncode $Text ]) };
    :if ([ :len [ /system/scheduler/find where name="_FlushTelegramQueue" ] ] = 0) do={
      /system/scheduler/add name="_FlushTelegramQueue" interval=1m start-time=startup \
        on-event=(":global FlushTelegramQueue; \$FlushTelegramQueue;");
    }
  }
}

# purge the Telegram queue
:set PurgeTelegramQueue do={
  :global TelegramQueue;

  /system/scheduler/remove [ find where name="_FlushTelegramQueue" ];
  :set TelegramQueue;
}

# send notification via telegram - expects at least two string arguments
:set SendTelegram do={ :onerror Err {
  :global SendTelegram2;

  $SendTelegram2 ({ origin=$0; subject=$1; message=$2; link=$3; silent=$4 });
} do={
  :global ExitError; $ExitError false $0 $Err;
} }

# send notification via telegram - expects one array argument
:set SendTelegram2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"telegram") ("\$NotificationFunctions->\"telegram\"") $Notification;
}
