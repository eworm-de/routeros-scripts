#!rsc by RouterOS
# Run with contrib/language-test.py --notifications; never sends a notification.
:global Captured;
:global CharacterMultiply;
:global EscapeForRegEx;
:global FlushMatrixQueue;
:global FlushTelegramQueue;
:global GetTelegramChatId;
:global Identity "test-router";
:global IdentityExtra "";
:global LogForwardFilterLogForwarding;
:global LogForwardFilterSubjects ({});
:global NotificationEMailSubject;
:global ScriptLanguage;
:global LanguageActive;
:global LanguageMessages;
:global Translate;

:global IsFullyConnected do={ :return false; }
:global CertificateAvailable do={ :return false; }
:global LogPrint do={ :global Captured; :set Captured $3; }
:global ExitOnError do={ :error $2; }
:global SymbolForNotification do={ :return ($1 . " "); }

:foreach Locale in={ "en"; "pt-BR" } do={
  :set ScriptLanguage $Locale;
  :set LanguageActive "pt-BR";
  $FlushMatrixQueue;
  :local Expected "System is not fully connected, not flushing.";
  :if ($Locale = "pt-BR") do={ :set Expected "O sistema n\C3\A3o est\C3\A1 totalmente conectado; a fila n\C3\A3o ser\C3\A1 processada."; };
  :if ($Captured != $Expected) do={ :error "Matrix guard failed"; }
  $FlushTelegramQueue;
  :if ($Captured != $Expected) do={ :error "Telegram guard failed"; }
  $GetTelegramChatId;
  :if ($Captured != [ $Translate "notification-telegram.certificate.failed" ]) do={
    :error "Telegram certificate guard failed";
  }
}

# Filter the original English subject, the selected language, and earlier subjects.
:local Subjects { "Log Forwarding"; "Encaminhamento de logs"; "Portugu\C3\AAs [teste].(log)" };
:local Filter "";
:foreach Subject in=$Subjects do={
  :set Filter [ $LogForwardFilterLogForwarding $Subject ];
}
:foreach Subject in=$Subjects do={
  :foreach Symbol in={ "memo"; "warning-sign" } do={
    :local Encoded [ $NotificationEMailSubject ($Symbol . " " . $Subject) ];
    :if (!(("Error sending e-mail <" . $Encoded . ">: test-error") ~ $Filter)) do={
      :error "Localized email loop filter failed";
    }
  }
}
:if ("Error sending e-mail <unrelated subject>: test-error" ~ $Filter) do={
  :error "Email loop filter matched an unrelated subject";
}
:put "Notification guards and localized email loop filter tests passed.";
