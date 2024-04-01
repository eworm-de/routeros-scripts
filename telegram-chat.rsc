#!rsc by RouterOS
# RouterOS script: telegram-chat
# Copyright (c) 2023-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.13
#
# use Telegram to chat with your Router and send commands
# https://git.eworm.de/cgit/routeros-scripts/about/doc/telegram-chat.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global Identity;
  :global TelegramChatActive;
  :global TelegramChatGroups;
  :global TelegramChatId;
  :global TelegramChatIdsTrusted;
  :global TelegramChatOffset;
  :global TelegramChatRunTime;
  :global TelegramMessageIDs;
  :global TelegramRandomDelay;
  :global TelegramTokenId;

  :global CertificateAvailable;
  :global EitherOr;
  :global EscapeForRegEx;
  :global GetRandom20CharAlNum;
  :global IfThenElse;
  :global LogPrint;
  :global MAX;
  :global MIN;
  :global MkDir;
  :global RandomDelay;
  :global ScriptLock;
  :global SendTelegram2;
  :global SymbolForNotification;
  :global ValidateSyntax;
  :global WaitForFile;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :error false;
  }

  $WaitFullyConnected;

  :if ([ :typeof $TelegramChatOffset ] != "array") do={
    :set TelegramChatOffset { 0; 0; 0 };
  }
  :if ([ :typeof $TelegramRandomDelay ] != "num") do={
    :set TelegramRandomDelay 0;
  }

  :if ([ $CertificateAvailable "Go Daddy Secure Certificate Authority - G2" ] = false) do={
    $LogPrint warning $ScriptName ("Downloading required certificate failed.");
    :error false;
  }

  $RandomDelay $TelegramRandomDelay;

  :local Data false;
  :for I from=1 to=4 do={
    :if ($Data = false) do={
      :do {
        :set Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
          ("https://api.telegram.org/bot" . $TelegramTokenId . "/getUpdates?offset=" . \
          $TelegramChatOffset->0 . "&allowed_updates=%5B%22message%22%5D") as-value ]->"data");
        :set TelegramRandomDelay [ $MAX 0 ($TelegramRandomDelay - 1) ];
      } on-error={
        :if ($I < 4) do={
          $LogPrint debug $ScriptName ("Fetch failed, " . $I . ". try.");
          :set TelegramRandomDelay [ $MIN 15 ($TelegramRandomDelay + 5) ];
          :delay (($I * $I) . "s");
        }
      }
    }
  }

  :if ($Data = false) do={
    $LogPrint warning $ScriptName ("Failed getting updates from Telegram.");
    :error false;
  }

  :local JSON [ :deserialize from=json value=$Data ];
  :local UpdateID 0;
  :local Uptime [ /system/resource/get uptime ];
  :foreach Update in=($JSON->"result") do={
    :set UpdateID ($Update->"update_id");
    :local Message ($Update->"message");
    :local IsReply [ :len ($Message->"reply_to_message") ];
    :local IsMyReply ($TelegramMessageIDs->[ :tostr ($Message->"reply_to_message"->"message_id") ]);
    :if (($IsMyReply = 1 || $TelegramChatOffset->0 > 0 || $Uptime > 5m) && $UpdateID >= $TelegramChatOffset->2) do={
      :local Trusted false;
      :local Chat ($Message->"chat");
      :local From ($Message->"from");

      :foreach IdsTrusted in=($TelegramChatId, $TelegramChatIdsTrusted) do={
        :if ($From->"id" = $IdsTrusted || $From->"username" = $IdsTrusted) do={
          :set Trusted true;
        }
      }

      :if ($Trusted = true) do={
        :local Done false;
        :if ($Message->"text" = "?") do={
          $LogPrint info $ScriptName ("Sending notice for update " . $UpdateID . ".");
          $SendTelegram2 ({ origin=$ScriptName; chatid=($Chat->"id"); silent=true; replyto=($Message->"message_id"); \
            subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
            message=("Online" . [ $IfThenElse $TelegramChatActive " (and active!)" ] . ", awaiting your commands!") });
          :set Done true;
        }
        :if ($Done = false && [ :pick ($Message->"text") 0 1 ] = "!") do={
          :if ($Message->"text" ~ ("^! *(" . [ $EscapeForRegEx $Identity ] . "|@" . $TelegramChatGroups . ")\$")) do={
            :set TelegramChatActive true;
          } else={
            :set TelegramChatActive false;
          }
          $LogPrint info $ScriptName ("Now " . [ $IfThenElse $TelegramChatActive "active" "passive" ] . \
            " from update " . $UpdateID . "!");
          :set Done true;
        }
        :if ($Done = false && ($IsMyReply = 1 || ($IsReply = 0 && $TelegramChatActive = true)) && [ :len ($Message->"text") ] > 0) do={
          :if ([ $ValidateSyntax ($Message->"text") ] = true) do={
            :local State "";
            :local File ("tmpfs/telegram-chat/" . [ $GetRandom20CharAlNum 6 ]);
            :if ([ $MkDir "tmpfs/telegram-chat" ] = false) do={
              $LogPrint error $ScriptName ("Failed creating directory!");
              :error false;
            }
            $LogPrint info $ScriptName ("Running command from update " . $UpdateID . ": " . $Message->"text");
            :execute script=(":do {\n" . $Message->"text" . "\n} on-error={ /file/add name=\"" . $File . ".failed\" };" . \
              "/file/add name=\"" . $File . ".done\"") file=($File . "\00");
            :if ([ $WaitForFile ($File . ".done") [ $EitherOr $TelegramChatRunTime 20s ] ] = false) do={
              :set State ([ $SymbolForNotification "warning-sign" ] . "The command did not finish, still running in background.\n\n");
            }
            :if ([ :len [ /file/find where name=($File . ".failed") ] ] > 0) do={
              :set State ([ $SymbolForNotification "cross-mark" ] . "The command failed with an error!\n\n");
            }
            :local Content ([ /file/read chunk-size=32768 file=$File as-value ]->"data");
            $SendTelegram2 ({ origin=$ScriptName; chatid=($Chat->"id"); silent=true; replyto=($Message->"message_id"); \
              subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
              message=([ $SymbolForNotification "gear" ] . "Command:\n" . $Message->"text" . "\n\n" . \
                $State . [ $IfThenElse ([ :len $Content ] > 0) \
                ([ $SymbolForNotification "memo" ] . "Output:\n" . $Content) \
                ([ $SymbolForNotification "memo" ] . "No output.") ]) });
            /file/remove "tmpfs/telegram-chat";
          } else={
            $LogPrint info $ScriptName ("The command from update " . $UpdateID . " failed syntax validation!");
            $SendTelegram2 ({ origin=$ScriptName; chatid=($Chat->"id"); silent=false; replyto=($Message->"message_id"); \
              subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
              message=([ $SymbolForNotification "gear" ] . "Command:\n" . $Message->"text" . "\n\n" . \
                [ $SymbolForNotification "cross-mark" ] . "The command failed syntax validation!") });
          }
        }
      } else={
        :local MessageText ("Received a message from untrusted contact " . \
          [ $IfThenElse ([ :len ($From->"username") ] = 0) "without username" ("'" . $From->"username" . "'") ] . \
          " (ID " . $From->"id" . ") in update " . $UpdateID . "!");
        :if ($Message->"text" ~ ("^! *" . [ $EscapeForRegEx $Identity ] . "\$")) do={
          $LogPrint warning $ScriptName $MessageText;
          $SendTelegram2 ({ origin=$ScriptName; chatid=($Chat->"id"); silent=false; replyto=($Message->"message_id"); \
            subject=([ $SymbolForNotification "speech-balloon" ] . "Telegram Chat"); \
            message=("You are not trusted.") });
        } else={
          $LogPrint info $ScriptName $MessageText;
        }
      }
    } else={
      $LogPrint debug $ScriptName ("Already handled update " . $UpdateID . ".");
    }
  }
  :set TelegramChatOffset ([ :pick $TelegramChatOffset 1 3 ], \
    [ $IfThenElse ($UpdateID >= $TelegramChatOffset->2) ($UpdateID + 1) ($TelegramChatOffset->2) ]);
} on-error={ }
