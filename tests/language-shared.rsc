# Simulate reads and capture logs; no real log entries or configuration changes.
:global Translate;
:global ScriptLanguage;
:global LanguageActive;
:global LanguageMessages;
:global LanguageEnglish;
:global LogPrintOnce;
:global LogPrintOnceMessages;
:global LogPrintOnceCrashMessages;
:global LogPrint;
:global SharedFixturePortuguese;
:global SharedFixtureDetect;
:global SharedFixtureFind;
:global SharedFixtureLog;
:global SharedFixtureWarning;
:global DeviceInfo;
:global GetMacVendor;
:global FormatLine;
:global IfThenElse;
:global CommitBrief;
:global IsMacLocallyAdministered;
:global Identity "test-router";
:global ExpectedConfigVersion 145;
:set IsMacLocallyAdministered do={ :return true; };
:set CommitBrief do={ :return "test-commit"; };
:set FormatLine do={ :return ($1 . ": " . $2); };
:set IfThenElse do={ :if ($1 = true) do={ :return $2; }; :return $3; };
:set LogPrint do={
  :global SharedFixtureWarning;
  :if ($1 = "warning") do={ :set SharedFixtureWarning $3; };
};
:set SharedFixtureFind do={
  :global SharedFixtureLog;
  :if ($1 = $SharedFixtureLog) do={ :return { "existing" }; };
  :return ({});
};
:set LogPrintOnceCrashMessages ({});
:foreach Locale in={ "en"; "pt-BR" } do={
  :set ScriptLanguage $Locale;
  :set LanguageActive "pt-BR";
  :set LanguageMessages $SharedFixturePortuguese;
  :set LogPrintOnceMessages ({});
  :set SharedFixtureWarning;
  $LogPrintOnce info "fixture" "duplicate";
  :local Expected "The message is already in log, scripting subsystem may have crashed before!";
  :local Vendor "locally administered";
  :local Label "Hostname: test-router";
  :if ($Locale = "pt-BR") do={
    :set Expected "A mensagem já está no log; o subsistema de scripts pode ter falhado anteriormente!";
    :set Vendor "administrado localmente";
    :set Label "Nome do host: test-router";
  }
  :if ($SharedFixtureWarning != $Expected || ($LogPrintOnceCrashMessages->$Expected) != true) do={
    :error "Translated crash warning was not recorded";
  }
  :set SharedFixtureLog ("\$LogPrintOnce: " . $Expected);
  :if ([ $SharedFixtureDetect ] != true) do={ :error "Translated crash warning was not detected"; }
  :if ([ $GetMacVendor "02:00:00:00:00:00" ] != $Vendor) do={ :error "MAC display translation failed"; }
  :if ([ :find [ $DeviceInfo ] $Label ] != 0) do={ :error "Device-info label translation failed"; }
  :if ([ $LogPrintOnce info "fixture" "duplicate" ] != false) do={ :error "Duplicate suppression changed"; }
}
# The old Portuguese warning remains detectable after switching to English.
:set ScriptLanguage "en";
:if ([ $SharedFixtureDetect ] != true) do={ :error "Crash detection failed across language changes"; }
# An English warning from an old installation needs no in-memory history.
:set LogPrintOnceCrashMessages ({});
:set SharedFixtureLog ("\$LogPrintOnce: " . ($LanguageEnglish->"global-functions.log.once.crash"));
:if ([ $SharedFixtureDetect ] != true) do={ :error "Legacy crash warning was not detected"; }
:set SharedFixtureLog "unrelated";
:if ([ $SharedFixtureDetect ] != false) do={ :error "Unrelated log entry matched"; }
:put "Shared diagnostics, device labels and crash detection across languages passed.";
