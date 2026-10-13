# Simulated inboxes; no API requests, command execution, or real SMS deletion.
:global GlobalConfigReady true;
:global GlobalFunctionsReady true;
:global Identity "test-router";
:global ScriptLock do={ :return true; };
:global WaitFullyConnected do={};
:global CertificateAvailable do={ :return true; };
:global RandomDelay do={};
:global SymbolForNotification do={ :return ""; };
:global LogPrint do={};
:global LogPrintVerbose do={};
:global ValidateSyntax do={ :return false; };
:global ExitOnError do={ :error $2; };
:global CapturedMessages;
:global CapturedCount;
:global SendTelegram2 do={
  :global CapturedMessages; :global CapturedCount;
  :set ($CapturedMessages->[ :tostr $CapturedCount ]) $1;
  :set CapturedCount ($CapturedCount + 1);
}
:global SendNotification2 do={
  :global CapturedMessages; :global CapturedCount;
  :set ($CapturedMessages->[ :tostr $CapturedCount ]) $1;
  :set CapturedCount ($CapturedCount + 1);
}
:global ChatFixtureRun;
:global ChatFixtureUpdates;
:global TelegramChatActive;
:global TelegramChatGroups "test-group";
:global TelegramChatId 123;
:global TelegramChatIdsTrusted ({});
:global TelegramChatOffset;
:global TelegramMessageIDs ({});
:global SmsForwardHooks ({});
:global SmsFixtureRun;
:global SmsFixtureIds;
:global SmsFixtureMessages;
:global SmsFixtureSettings { "allowed-number"="commands-only"; "secret"="fixture" };
:global ScriptLanguage;
:global LanguageActive;
:global Translate;

:foreach Locale in={ "en"; "pt-BR" } do={
  :set ScriptLanguage $Locale;
  :set LanguageActive "pt-BR";
  :set TelegramChatActive false;
  :set TelegramChatOffset { 1; 1; 1 };
  :set CapturedMessages ({});
  :set CapturedCount 0;
  :local Updates ({});
  :local Id 1;
  :foreach Command in={ "?"; "! test-router"; "?"; "invalid command"; "! other-router"; "?"; "! test-router"; "?" } do={
    :local Sender 123;
    :if ($Id > 6) do={ :set Sender 999; };
    :local Message { "text"=$Command; "message_id"=$Id; "chat"={ "id"=$Sender }; "from"={ "id"=$Sender; "first_name"="Tester" } };
    :set Updates ($Updates, { { "update_id"=$Id; "message"=$Message } });
    :set Id ($Id + 1);
  }
  :set ChatFixtureUpdates { "result"=$Updates };
  $ChatFixtureRun;
  :if ($CapturedCount != 5 || $TelegramChatActive != false || ($TelegramChatOffset->2) != 9) do={ :error "Telegram routing or offset failed"; };
  :local Passive "Hello Tester!\n\nOnline, awaiting your commands!";
  :local Active "Hello Tester!\n\nOnline (and active!), awaiting your commands!";
  :local Invalid "Command:\ninvalid command\n\nThe command failed syntax validation!";
  :local Denied "You are not trusted.";
  :local Subject "Telegram Chat";
  :if ($Locale = "pt-BR") do={
    :set Passive "Ol\C3\A1 Tester!\n\nOnline, aguardando seus comandos!";
    :set Active "Ol\C3\A1 Tester!\n\nOnline (e ativo!), aguardando seus comandos!";
    :set Invalid "Comando:\ninvalid command\n\nA sintaxe do comando \C3\A9 inv\C3\A1lida!";
    :set Denied "Voc\C3\AA n\C3\A3o \C3\A9 um contato confi\C3\A1vel.";
    :set Subject "Conversa pelo Telegram";
  }
  :if (($CapturedMessages->"0"->"message") != $Passive || ($CapturedMessages->"1"->"message") != $Active || ($CapturedMessages->"3"->"message") != $Passive) do={ :error "Telegram greeting failed"; };
  :if (($CapturedMessages->"2"->"message") != $Invalid || ($CapturedMessages->"4"->"message") != $Denied) do={ :error "Telegram command rejection failed"; };
  :if (($CapturedMessages->"0"->"subject") != $Subject) do={ :error "Telegram subject failed"; };

  :foreach Count in={ 1; 2 } do={
    :set CapturedMessages ({});
    :set CapturedCount 0;
    :set SmsFixtureIds { "first" };
    :if ($Count = 2) do={ :set SmsFixtureIds { "first"; "second" }; };
    :set SmsFixtureMessages {
      "first"={ "timestamp"="2026-10-09 12:00:00"; "type"="text"; "message"="first {identity}" };
      "second"={ "timestamp"="2026-10-09 12:01:00"; "type"="text"; "message"="second message" }
    };
    $SmsFixtureRun;
    :if ($CapturedCount != 1 || [ :len $SmsFixtureIds ] != 0) do={ :error "SMS grouping or cleanup failed"; };
    :local Received "\n\nOn 2026-10-09 12:00:00 type text:\nfirst {identity}";
    :local Second "\n\nOn 2026-10-09 12:01:00 type text:\nsecond message";
    :if ($Locale = "pt-BR") do={
      :set Received "\n\nEm 2026-10-09 12:00:00, tipo text:\nfirst {identity}";
      :set Second "\n\nEm 2026-10-09 12:01:00, tipo text:\nsecond message";
    }
    :if ($Count = 2) do={ :set Received ($Received . $Second); };
    :local Expected "Received this message by test-router from test-phone:";
    :if ($Count = 2) do={ :set Expected "Received these 2 messages by test-router from test-phone:"; };
    :if ($Locale = "pt-BR") do={
      :set Expected "Mensagem recebida por test-router de test-phone:";
      :if ($Count = 2) do={ :set Expected "2 mensagens recebidas por test-router de test-phone:"; };
    }
    :if (($CapturedMessages->"0"->"message") != ($Expected . $Received)) do={ :error "SMS forwarding body failed"; };
    :set Expected "SMS Forwarding from test-phone";
    :if ($Locale = "pt-BR") do={ :set Expected "Encaminhamento de SMS de test-phone"; };
    :if (($CapturedMessages->"0"->"subject") != $Expected) do={ :error "SMS forwarding subject failed"; };
  }
}
:put "Simulated SMS forwarding and Telegram authorization tests passed.";
