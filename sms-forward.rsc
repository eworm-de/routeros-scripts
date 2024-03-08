#!rsc by RouterOS
# RouterOS script: sms-forward
# Copyright (c) 2013-2024 Christian Hesse <mail@eworm.de>
#                         Anatoly Bubenkov <bubenkoff@gmail.com>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.12
#
# forward SMS to e-mail
# https://git.eworm.de/cgit/routeros-scripts/about/doc/sms-forward.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global Identity;
  :global SmsForwardHooks;

  :global IfThenElse;
  :global LogPrintExit2;
  :global LogPrintOnce;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global ValidateSyntax;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :error false;
  }

  :if ([ /tool/sms/get receive-enabled ] = false) do={
    $LogPrintOnce warning $ScriptName ("Receiving of SMS is not enabled.");
    :error false;
  }

  $WaitFullyConnected;

  :local Settings [ /tool/sms/get ];

  :if ([ /interface/lte/get ($Settings->"port") running ] != true) do={
    $LogPrintExit2 info $ScriptName ("The LTE interface is not in running state, skipping.") false;
    :error true;
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
        $LogPrintExit2 debug $ScriptName ("Removing SMS, which started a script.") false;
        /tool/sms/inbox/remove $Sms;
      } else={
        :set Messages ($Messages . "\n\nOn " . $SmsVal->"timestamp" . \
            " type " . $SmsVal->"type" . ":\n" . $SmsVal->"message");
        :foreach Hook in=$SmsForwardHooks do={
          :if ($Phone~($Hook->"allowed-number") && ($SmsVal->"message")~($Hook->"match")) do={
            :if ([ $ValidateSyntax ($Hook->"command") ] = true) do={
              $LogPrintExit2 info $ScriptName ("Running hook '" . $Hook->"match" . "': " . \
                  $Hook->"command") false;
              :do {
                :local Command [ :parse ($Hook->"command") ];
                $Command Phone=$Phone Message=($SmsVal->"message");
                :set Messages ($Messages . "\n\nRan hook '" . $Hook->"match" . "':\n" . \
                    $Hook->"command");
              } on-error={
                $LogPrintExit2 warning $ScriptName ("The code for hook '" . $Hook->"match" . \
                    "' failed to run!") false;
              }
            } else={
              $LogPrintExit2 warning $ScriptName ("The code for hook '" . $Hook->"match" . \
                  "' failed syntax validation!") false;
            }
          }
        }
        :set Delete ($Delete, $Sms);
      }
    }

    :if ([ :len $Messages ] > 0) do={
      :local Count [ :len $Delete ];
      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "incoming-envelope" ] . "SMS Forwarding from " . $Phone); \
        message=("Received " . [ $IfThenElse ($Count = 1) "this message" ("these " . $Count . " messages") ] . \
          " by " . $Identity . " from " . $Phone . ":" . $Messages) });
      :foreach Sms in=$Delete do={
        /tool/sms/inbox/remove $Sms;
      }
    }
  }
} on-error={ }
