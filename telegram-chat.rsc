#!rsc by RouterOS
# RouterOS script: telegram-chat
# Copyright (c) 2023-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch
#
# use Telegram to chat with your Router and send commands
# https://rsc.eworm.de/doc/telegram-chat.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=telegram-chat, schema=23866b98057d30494867d66d781c3555fc2f373d9af75cb1aac34c965ee3bd54
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"telegram-chat.certificate.failed") "Downloading required certificate failed.";
:set ($LanguageEnglish->"telegram-chat.command") "Command:\0A{command}\0A\0A";
:set ($LanguageEnglish->"telegram-chat.command.background") "The command did not finish, still running in background.\0A\0A";
:set ($LanguageEnglish->"telegram-chat.command.failed") "The command failed with an error!\0A\0A";
:set ($LanguageEnglish->"telegram-chat.command.running") "Running command from update {id}: {command}";
:set ($LanguageEnglish->"telegram-chat.command.syntax") "The command from update {id} failed syntax validation!";
:set ($LanguageEnglish->"telegram-chat.command.syntax.message") "The command failed syntax validation!";
:set ($LanguageEnglish->"telegram-chat.directory.failed") "Failed creating directory!";
:set ($LanguageEnglish->"telegram-chat.fetch.failed") "Fetch failed, {count}. try: {error}";
:set ($LanguageEnglish->"telegram-chat.greeting") "Hello {name}!\0A\0A";
:set ($LanguageEnglish->"telegram-chat.notice") "Sending notice for update {id}.";
:set ($LanguageEnglish->"telegram-chat.online.active") "Online (and active!), awaiting your commands!";
:set ($LanguageEnglish->"telegram-chat.online.passive") "Online, awaiting your commands!";
:set ($LanguageEnglish->"telegram-chat.output") "Output:\0A{output}";
:set ($LanguageEnglish->"telegram-chat.output.empty") "No output.";
:set ($LanguageEnglish->"telegram-chat.state.active") "Now active from update {id}!";
:set ($LanguageEnglish->"telegram-chat.state.passive") "Now passive from update {id}!";
:set ($LanguageEnglish->"telegram-chat.subject") "Telegram Chat";
:set ($LanguageEnglish->"telegram-chat.untrusted.message") "You are not trusted.";
:set ($LanguageEnglish->"telegram-chat.untrusted.named") "Received a message from untrusted contact '{username}' (ID {contact}) in update {id}!";
:set ($LanguageEnglish->"telegram-chat.untrusted.unnamed") "Received a message from untrusted contact without username (ID {contact}) in update {id}!";
:set ($LanguageEnglish->"telegram-chat.update") "Update {id}: {update}";
:set ($LanguageEnglish->"telegram-chat.update.handled") "Already handled update {id}.";
:set ($LanguageEnglish->"telegram-chat.updates.failed") "Failed getting updates.";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :global GlobalNotReadyMessage;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error $GlobalNotReadyMessage; }; } delay=500ms max=50;
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
  :global FileExists;
  :global GetRandom20CharAlNum;
  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global LogPrintVerbose;
  :global MAX;
  :global MIN;
  :global MkDir;
  :global RandomDelay;
  :global RmDir;
  :global ScriptLock;
  :global SendTelegram2;
  :global SymbolForNotification;
  :global ValidateSyntax;
  :global WaitForFile;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  $WaitFullyConnected;

  :if ([ :typeof $TelegramChatOffset ] != "array") do={
    :set TelegramChatOffset { 0; 0; 0 };
  }
  :if ([ :typeof $TelegramRandomDelay ] != "num") do={
    :set TelegramRandomDelay 0;
  }

  :if ([ $CertificateAvailable "Go Daddy Root Certificate Authority - G2" "fetch" ] = false) do={
    $LogPrint warning $ScriptName [ $Translate "telegram-chat.certificate.failed" ];
    :exit;
  }

  $RandomDelay $TelegramRandomDelay;

  :local Data false;
  :for I from=1 to=4 do={
    :onerror Err {
      :set Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
        ("https://api.telegram.org/bot" . $TelegramTokenId . "/getUpdates?offset=" . \
        $TelegramChatOffset->0 . "&allowed_updates=%5B%22message%22%5D") as-value ]->"data");
      :set TelegramRandomDelay [ $MAX 0 ($TelegramRandomDelay - 1) ];
      :break;
    } do={
      :if ($I < 4) do={
        $LogPrint debug $ScriptName [ $Translate "telegram-chat.fetch.failed" \
            ({ count=$I; error=$Err }) ];
        :set TelegramRandomDelay [ $MIN 15 ($TelegramRandomDelay + 5) ];
        :delay (($I * $I) . "s");
      }
    }
  }

  :if ($Data = false) do={
    $LogPrint warning $ScriptName [ $Translate "telegram-chat.updates.failed" ];
    :exit;
  }

  :local JSON [ :deserialize from=json value=$Data ];
  :local UpdateID 0;
  :local Uptime [ /system/resource/get uptime ];
  :foreach Update in=($JSON->"result") do={
    :set UpdateID ($Update->"update_id");
    $LogPrintVerbose debug $ScriptName [ $Translate "telegram-chat.update" \
        ({ id=$UpdateID; update=[ :serialize to=json $Update ] }) ];

    :local Message ($Update->"message");
    :local IsAnyReply ([ :typeof ($Message->"reply_to_message") ] = "array");
    :local IsMyReply ($TelegramMessageIDs->[ :tostr ($Message->"reply_to_message"->"message_id") ]);
    :if (($IsMyReply = 1 || $TelegramChatOffset->0 > 0 || $Uptime > 5m) && $UpdateID >= $TelegramChatOffset->2) do={
      :local Trusted false;
      :local Chat ($Message->"chat");
      :local From ($Message->"from");
      :local Command ($Message->"text");
      :local ThreadId [ $IfThenElse ($Message->"is_topic_message") ($Message->"message_thread_id") "" ];

      :foreach IdsTrusted in=($TelegramChatId, $TelegramChatIdsTrusted) do={
        :if ($From->"id" = $IdsTrusted || \
             $From->"username" = $IdsTrusted || \
             $Chat->"id" = $IdsTrusted) do={
          :set Trusted true;
        }
      }

      :if ($Trusted = true) do={
        :if ($Command = "?") do={
          $LogPrint info $ScriptName [ $Translate "telegram-chat.notice" \
              ({ id=$UpdateID }) ];
          $SendTelegram2 ({ origin=$ScriptName; chatid=($Chat->"id"); silent=true; \
            replyto=($Message->"message_id"); threadid=$ThreadId; \
            subject=([ $SymbolForNotification "speech-balloon" ] . [ $Translate "telegram-chat.subject" ]); \
            message=([ $IfThenElse ([ :len ($From->"first_name") ] > 0) [ $Translate "telegram-chat.greeting" \
                ({ name=($From->"first_name") }) ] ] . \
              [ $IfThenElse $TelegramChatActive [ $Translate "telegram-chat.online.active" ] [ $Translate "telegram-chat.online.passive" ] ]) });
          :continue;
        }
        :if ([ :pick $Command 0 1 ] = "!") do={
          :if ($Command ~ ("^! *(" . [ $EscapeForRegEx $Identity ] . "|@" . $TelegramChatGroups . ")\$")) do={
            :set TelegramChatActive true;
          } else={
            :set TelegramChatActive false;
          }
          $LogPrint info $ScriptName [ $IfThenElse $TelegramChatActive [ $Translate "telegram-chat.state.active" ({ id=$UpdateID }) ] [ $Translate "telegram-chat.state.passive" \
              ({ id=$UpdateID }) ] ];
          :continue;
        }
        :if (($IsMyReply = 1 || ($IsAnyReply = false && \
             $TelegramChatActive = true)) && [ :len $Command ] > 0) do={
          :if ([ $ValidateSyntax $Command ] = true) do={
            :local State "";
            :local File ("tmpfs/telegram-chat/" . [ $GetRandom20CharAlNum 6 ]);
            :if ([ $MkDir "tmpfs/telegram-chat" ] = false) do={
              $LogPrint error $ScriptName [ $Translate "telegram-chat.directory.failed" ];
              :exit;
            }
            $LogPrint info $ScriptName [ $Translate "telegram-chat.command.running" \
                ({ id=$UpdateID; command=$Command }) ];
            :execute script=(":do {\n" . $Command . "\n} on-error={ /file/add name=\"" . $File . ".failed\" };" . \
              "/file/add name=\"" . $File . ".done\"") file=($File . "\00");
            :if ([ $WaitForFile ($File . ".done") [ $EitherOr $TelegramChatRunTime 20s ] ] = false) do={
              :set State ([ $SymbolForNotification "warning-sign" ] . [ $Translate "telegram-chat.command.background" ]);
            }
            :if ([ $FileExists ($File . ".failed") ] = true) do={
              :set State ([ $SymbolForNotification "cross-mark" ] . [ $Translate "telegram-chat.command.failed" ]);
            }
            :local Content ([ /file/read chunk-size=32768 file=$File as-value ]->"data");
            $SendTelegram2 ({ origin=$ScriptName; chatid=($Chat->"id"); silent=true; \
              replyto=($Message->"message_id"); threadid=$ThreadId; \
              subject=([ $SymbolForNotification "speech-balloon" ] . [ $Translate "telegram-chat.subject" ]); \
              message=([ $SymbolForNotification "gear" ] . [ $Translate "telegram-chat.command" \
                  ({ command=$Command }) ] . \
                $State . [ $IfThenElse ([ :len $Content ] > 0) \
                ([ $SymbolForNotification "memo" ] . [ $Translate "telegram-chat.output" \
                    ({ output=$Content }) ]) \
                ([ $SymbolForNotification "memo" ] . [ $Translate "telegram-chat.output.empty" ]) ]) });
            $RmDir "tmpfs/telegram-chat";
          } else={
            $LogPrint info $ScriptName [ $Translate "telegram-chat.command.syntax" \
                ({ id=$UpdateID }) ];
            $SendTelegram2 ({ origin=$ScriptName; chatid=($Chat->"id"); silent=false; \
              replyto=($Message->"message_id"); threadid=$ThreadId; \
              subject=([ $SymbolForNotification "speech-balloon" ] . [ $Translate "telegram-chat.subject" ]); \
              message=([ $SymbolForNotification "gear" ] . [ $Translate "telegram-chat.command" \
                  ({ command=$Command }) ] . \
                [ $SymbolForNotification "cross-mark" ] . [ $Translate "telegram-chat.command.syntax.message" ]) });
          }
        }
      } else={
        :local MessageText [ $Translate "telegram-chat.untrusted.unnamed" \
            ({ contact=($From->"id"); id=$UpdateID }) ];
        :if ([ :len ($From->"username") ] > 0) do={ :set MessageText [ $Translate "telegram-chat.untrusted.named" \
            ({ username=($From->"username"); contact=($From->"id"); id=$UpdateID }) ]; };
        :if ($Command ~ ("^! *" . [ $EscapeForRegEx $Identity ] . "\$")) do={
          $LogPrint warning $ScriptName $MessageText;
          $SendTelegram2 ({ origin=$ScriptName; chatid=($Chat->"id"); silent=false; \
            replyto=($Message->"message_id"); threadid=$ThreadId; \
            subject=([ $SymbolForNotification "speech-balloon" ] . [ $Translate "telegram-chat.subject" ]); \
            message=[ $Translate "telegram-chat.untrusted.message" ] });
        } else={
          $LogPrint info $ScriptName $MessageText;
        }
      }
    } else={
      $LogPrint debug $ScriptName [ $Translate "telegram-chat.update.handled" \
          ({ id=$UpdateID }) ];
    }
  }
  :set TelegramChatOffset ([ :pick $TelegramChatOffset 1 3 ], \
    [ $IfThenElse ($UpdateID >= $TelegramChatOffset->2) ($UpdateID + 1) ($TelegramChatOffset->2) ]);
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
