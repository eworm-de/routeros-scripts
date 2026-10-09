#!rsc by RouterOS
# RouterOS script: sms-forward
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
#                         Anatoly Bubenkov <bubenkoff@gmail.com>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# forward SMS to e-mail
# https://rsc.eworm.de/doc/sms-forward.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=sms-forward, schema=b605613f43230d212520e682ee06789fe9ebdb37a25f5c21ba93719a7923e2a1
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"sms-forward.command.removed") "Removing SMS, which started a script.";
:set ($LanguageEnglish->"sms-forward.disabled") "Receiving of SMS is not enabled.";
:set ($LanguageEnglish->"sms-forward.hook.failed") "The code for hook '{match}' failed to run: {error}";
:set ($LanguageEnglish->"sms-forward.hook.ran") "\0A\0ARan hook '{match}':\0A{command}";
:set ($LanguageEnglish->"sms-forward.hook.running") "Running hook '{match}': {command}";
:set ($LanguageEnglish->"sms-forward.hook.syntax") "The code for hook '{match}' failed syntax validation!";
:set ($LanguageEnglish->"sms-forward.interface.stopped") "The LTE interface is not in running state, skipping.";
:set ($LanguageEnglish->"sms-forward.message.many") "Received these {count} messages by {identity} from {phone}:{messages}";
:set ($LanguageEnglish->"sms-forward.message.one") "Received this message by {identity} from {phone}:{messages}";
:set ($LanguageEnglish->"sms-forward.received") "On {timestamp} type {type}:\0A{message}";
:set ($LanguageEnglish->"sms-forward.remove.failed") "Failed to remove message: {error}";
:set ($LanguageEnglish->"sms-forward.subject") "SMS Forwarding from {phone}";
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
  :global SmsForwardHooks;

  :global IfThenElse;
  :global LogPrint;
  :global Translate;
  :global LogPrintOnce;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global ValidateSyntax;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :if ([ /tool/sms/get receive-enabled ] = false) do={
    $LogPrintOnce warning $ScriptName [ $Translate "sms-forward.disabled" ];
    :exit;
  }

  $WaitFullyConnected;

  :local Settings [ /tool/sms/get ];

  :if ([ /interface/lte/get ($Settings->"port") running ] != true) do={
    $LogPrint info $ScriptName [ $Translate "sms-forward.interface.stopped" ];
    :exit;
  }

  # forward SMS in a loop
  :while ([ :len [ /tool/sms/inbox/find ] ] > 0) do={
    :local Phone [ /tool/sms/inbox/get ([ find ]->0) phone ];
    :local Messages "";
    :local Delete ({});

    :foreach Sms in=[ /tool/sms/inbox/find where phone=$Phone ] do={
      :local SmsVal [ /tool/sms/inbox/get $Sms ];

      :if ($Phone = $Settings->"allowed-number" && \
          ($SmsVal->"message")~("^:cmd " . $Settings->"secret" . " script ")) do={
        $LogPrint debug $ScriptName [ $Translate "sms-forward.command.removed" ];
        :onerror Err {
          /tool/sms/inbox/remove $Sms;
          :delay 50ms;
        } do={
          $LogPrint warning $ScriptName [ $Translate "sms-forward.remove.failed" \
              ({ error=$Err }) ];
        }
      } else={
        :set Messages ($Messages . "\n\n" . [ $SymbolForNotification "incoming-envelope" ] . \
            [ $Translate "sms-forward.received" \
                ({ timestamp=($SmsVal->"timestamp"); type=($SmsVal->"type"); message=($SmsVal->"message") }) ]);
        :foreach Hook in=$SmsForwardHooks do={
          :if ($Phone~($Hook->"allowed-number") && ($SmsVal->"message")~($Hook->"match")) do={
            :if ([ $ValidateSyntax ($Hook->"command") ] = true) do={
              $LogPrint info $ScriptName [ $Translate "sms-forward.hook.running" \
                  ({ match=($Hook->"match"); command=($Hook->"command") }) ];
              :onerror Err {
                :local Command [ :parse ($Hook->"command") ];
                $Command Phone=$Phone Message=($SmsVal->"message");
                :set Messages ($Messages . [ $Translate "sms-forward.hook.ran" \
                    ({ match=($Hook->"match"); command=($Hook->"command") }) ]);
              } do={
                $LogPrint warning $ScriptName [ $Translate "sms-forward.hook.failed" \
                    ({ match=($Hook->"match"); error=$Err }) ];
              }
            } else={
              $LogPrint warning $ScriptName [ $Translate "sms-forward.hook.syntax" \
                  ({ match=($Hook->"match") }) ];
            }
          }
        }
        :set Delete ($Delete, $Sms);
      }
    }

    :if ([ :len $Messages ] > 0) do={
      :local Count [ :len $Delete ];
      :local Summary [ $Translate "sms-forward.message.many" \
          ({ count=$Count; identity=$Identity; phone=$Phone; messages=$Messages }) ];
      :if ($Count = 1) do={ :set Summary [ $Translate "sms-forward.message.one" \
          ({ identity=$Identity; phone=$Phone; messages=$Messages }) ]; };
      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "incoming-envelope" ] . [ $Translate "sms-forward.subject" \
            ({ phone=$Phone }) ]); \
        message=$Summary });
      :foreach Sms in=$Delete do={
        :onerror Err {
          /tool/sms/inbox/remove $Sms;
          :delay 50ms;
        } do={
          $LogPrint warning $ScriptName [ $Translate "sms-forward.remove.failed" \
              ({ error=$Err }) ];
        }
      }
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
