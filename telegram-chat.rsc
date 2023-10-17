#!rsc by RouterOS
# RouterOS script: telegram-chat
# Copyright (c) 2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# use Telegram to chat with your Router and send commands
# https://git.eworm.de/cgit/routeros-scripts/about/doc/telegram-chat.md

:local 0 "telegram-chat";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global Identity;
:global TelegramChatActive;
:global TelegramChatGroups;
:global TelegramChatId;
:global TelegramChatIdsTrusted;
:global TelegramChatOffset;
:global TelegramChatRunTime;
:global TelegramMessageIDs;
:global TelegramTokenId;

:global CertificateAvailable;
:global EitherOr;
:global EscapeForRegEx;
:global GetRandom20CharAlNum;
:global IfThenElse;
:global LogPrintExit2;
:global MkDir;
:global ParseJson;
:global ScriptLock;
:global SendTelegram2;
:global SymbolForNotification;
:global ValidateSyntax;
:global WaitForFile;
:global WaitFullyConnected;

$ScriptLock $0;

$WaitFullyConnected;

:if ([ :typeof $TelegramChatOffset ] != "array") do={
  :set TelegramChatOffset { 0; 0; 0 };
}

:if ([ $CertificateAvailable "Go Daddy Secure Certificate Authority - G2" ] = false) do={
  $LogPrintExit2 warning $0 ("Downloading required certificate failed.") true;
}

:local Data false;
:for I from=2 to=0 do={
  :if ($Data = false) do={
    :do {
      :set Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
        ("https://api.telegram.org/bot" . $TelegramTokenId . "/getUpdates?offset=" . \
        $TelegramChatOffset->0 . "&allowed_updates=%5B%22message%22%5D") as-value ]->"data");
    } on-error={
      $LogPrintExit2 debug $0 ("Fetch failed, " . $I . " retries pending.") false;
      :delay 2s;
    }
  }
}

:if ($Data = false) do={
  $LogPrintExit2 warning $0 ("Failed getting updates from Telegram.") true;
}

:local UpdateID 0;
:local Uptime [ /system/resource/get uptime ];
:foreach UpdateArray in=[ :toarray ([ $ParseJson $Data ]->"result") ] do={
  :local Update [ $ParseJson $UpdateArray ];
  :set UpdateID ($Update->"update_id");
  :local Message [ $ParseJson ($Update->"message") ];
  :local IsReply [ :len ($Message->"reply_to_message") ];
  :local IsMyReply ($TelegramMessageIDs->([ $ParseJson ($Message->"reply_to_message") ]->"message_id"));
  :if (($IsMyReply = 1 || $TelegramChatOffset->0 > 0 || $Uptime > 5m) && $UpdateID >= $TelegramChatOffset->2) do={
    :local Trusted false;
    :local Chat [ $ParseJson ($Message->"chat") ];
    :local From [ $ParseJson ($Message->"from") ];

    :foreach IdsTrusted in=($TelegramChatId, $TelegramChatIdsTrusted) do={
      :if ($From->"id" = $IdsTrusted || $From->"username" = $IdsTrusted) do={
        :set Trusted true;
      }
    }

    :if ($Trusted = true) do={
      :local Done false;
      :if ($Message->"text" = "?") do={
        $SendTelegram2 ({ origin=$0; chatid=($Chat->"id"); silent=true; replyto=($Message->"message_id"); \
          subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
          message=("Online, awaiting your commands!") });
        :set Done true;
      }
      :if ($Done = false && [ :pick ($Message->"text") 0 1 ] = "!") do={
        :if ($Message->"text" ~ ("^! *(" . [ $EscapeForRegEx $Identity ] . "|@" . $TelegramChatGroups . ")\$")) do={
          :set TelegramChatActive true;
        } else={
          :set TelegramChatActive false;
        }
        $LogPrintExit2 info $0 ("Now " . [ $IfThenElse $TelegramChatActive "active" "passive" ] . \
          " from update " . $UpdateID . "!") false;
        :set Done true;
      }
      :if ($Done = false && ($IsMyReply = 1 || ($IsReply = 0 && $TelegramChatActive = true)) && [ :len ($Message->"text") ] > 0) do={
        :if ([ $ValidateSyntax ($Message->"text") ] = true) do={
          :local State "";
          :local File ("tmpfs/telegram-chat/" . [ $GetRandom20CharAlNum 6 ]);
          $MkDir "tmpfs/telegram-chat";
          $LogPrintExit2 info $0 ("Running command from update " . $UpdateID . ": " . $Message->"text") false;
          :execute script=(":do {\n" . $Message->"text" . "\n} on-error={ /file/add name=\"" . $File . ".failed\" };" . \
            "/file/add name=\"" . $File . ".done\"") file=$File;
          :if ([ $WaitForFile ($File . ".done") [ $EitherOr $TelegramChatRunTime 20s ] ] = false) do={
            :set State "The command did not finish, still running in background.\n\n";
          }
          :if ([ :len [ /file/find where name=($File . ".failed") ] ] > 0) do={
            :set State "The command failed with an error!\n\n";
          }
          :local Content [ /file/get ($File . ".txt") contents ];
          $SendTelegram2 ({ origin=$0; chatid=($Chat->"id"); silent=true; replyto=($Message->"message_id"); \
            subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
            message=("Command:\n" . $Message->"text" . "\n\n" . $State . [ $IfThenElse ([ :len $Content ] > 0) \
              ("Output:\n" . $Content) [ $IfThenElse ([ /file/get ($File . ".txt") size ] > 0) \
              ("Output exceeds file read size.") ("No output.") ] ]) });
          /file/remove "tmpfs/telegram-chat";
        } else={
          $LogPrintExit2 info $0 ("The command from update " . $UpdateID . " failed syntax validation!") false;
          $SendTelegram2 ({ origin=$0; chatid=($Chat->"id"); silent=false; replyto=($Message->"message_id"); \
            subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
            message=("Command:\n" . $Message->"text" . "\n\nThe command failed syntax validation!") });
        }
      }
    } else={
      :local MessageText ("Received a message from untrusted contact " . \
        [ $IfThenElse ([ :len ($From->"username") ] = 0) "without username" ("'" . $From->"username" . "'") ] . \
        " (ID " . $From->"id" . ") in update " . $UpdateID . "!");
      :if ($Message->"text" ~ ("^! *" . [ $EscapeForRegEx $Identity ] . "\$")) do={
        $LogPrintExit2 warning $0 $MessageText false;
        $SendTelegram2 ({ origin=$0; chatid=($Chat->"id"); silent=false; replyto=($Message->"message_id"); \
          subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
          message=("You are not trusted.") });
      } else={
        $LogPrintExit2 info $0 $MessageText false;
      }
    }
  } else={
    $LogPrintExit2 debug $0 ("Already handled update " . $UpdateID . ".") false;
  }
}
:set TelegramChatOffset ([ :pick $TelegramChatOffset 1 3 ], \
  [ $IfThenElse ($UpdateID >= $TelegramChatOffset->2) ($UpdateID + 1) ($TelegramChatOffset->2) ]);
