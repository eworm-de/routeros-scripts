#!rsc by RouterOS
# RouterOS script: sms-forward
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
#                         Anatoly Bubenkov <bubenkoff@gmail.com>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.19
#
# forward SMS to e-mail
# https://rsc.eworm.de/doc/sms-forward.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global Identity;
  :global SmsForwardHooks;

  :global IfThenElse;
  :global LogPrint;
  :global LogPrintOnce;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global ValidateSyntax;
  :global WaitFullyConnected;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :if ([ /tool/sms/get receive-enabled ] = false) do={
    $LogPrintOnce warning $ScriptName ("Receiving of SMS is not enabled.");
    :set ExitOK true;
    :error false;
  }

  $WaitFullyConnected;

  :local Settings [ /tool/sms/get ];

  :if ([ /interface/lte/get ($Settings->"port") running ] != true) do={
    $LogPrint info $ScriptName ("The LTE interface is not in running state, skipping.");
    :set ExitOK true;
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
        $LogPrint debug $ScriptName ("Removing SMS, which started a script.");
        :onerror Err {
          /tool/sms/inbox/remove $Sms;
          :delay 50ms;
        } do={
          $LogPrint warning $ScriptName ("Failed to remove message: " . $Err);
        }
      } else={
        :set Messages ($Messages . "\n\n" . [ $SymbolForNotification "incoming-envelope" ] . \
            "On " . $SmsVal->"timestamp" . " type " . $SmsVal->"type" . ":\n" . $SmsVal->"message");
        :foreach Hook in=$SmsForwardHooks do={
          :if ($Phone~($Hook->"allowed-number") && ($SmsVal->"message")~($Hook->"match")) do={
            :if ([ $ValidateSyntax ($Hook->"command") ] = true) do={
              $LogPrint info $ScriptName ("Running hook '" . $Hook->"match" . "': " . $Hook->"command");
              :onerror Err {
                :local Command [ :parse ($Hook->"command") ];
                $Command Phone=$Phone Message=($SmsVal->"message");
                :set Messages ($Messages . "\n\nRan hook '" . $Hook->"match" . "':\n" . $Hook->"command");
              } do={
                $LogPrint warning $ScriptName ("The code for hook '" . $Hook->"match" . "' failed to run: " . $Err);
              }
            } else={
              $LogPrint warning $ScriptName ("The code for hook '" . $Hook->"match" . "' failed syntax validation!");
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
        :onerror Err {
          /tool/sms/inbox/remove $Sms;
          :delay 50ms;
        } do={
          $LogPrint warning $ScriptName ("Failed to remove message: " . $Err);
        }
      }
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
