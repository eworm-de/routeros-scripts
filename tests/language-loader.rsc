#!rsc by RouterOS
# Added by contrib/language-test.py --base-url in an isolated test bundle.
:global LanguageUpdate;
:global Translate;
:global LanguageSchemas;
:global ScriptLanguage;
:global ScriptUpdatesBaseUrl;
:global LanguageMessages;
:global LanguageActive;

:local Prefix "";
:if ([ :len [ /file/find where name="flash" ] ] > 0) do={ :set Prefix "flash/"; }
:local Cache ($Prefix . "language-pt-BR-check-health.json");
:if ([ :len [ /file/find where name=$Cache ] ] > 0) do={
  :error "Test cache already exists; refusing to overwrite it.";
}
:onerror LoaderError {
  :set ScriptLanguage "en";
  $LanguageUpdate;
  :if ($LanguageActive != "en" || [ :len $LanguageMessages ] != 0) do={
    :error "English loader default failed";
  }
  :set ScriptLanguage "pt-BR";
  $LanguageUpdate;
  :if ([ $Translate "check-health.cpu.warning.subject" ] = "Health warning: CPU utilization") do={
    :error "HTTPS catalog download failed";
  }
  :if ([ :len [ /file/find where name=$Cache ] ] != 1) do={ :error "Catalog cache not written"; }
  :local Cached [ /file/get [ find where name=$Cache ] contents ];
  $LanguageUpdate;
  :if ([ /file/get [ find where name=$Cache ] contents ] != $Cached) do={
    :error "Unchanged catalog cache differed";
  }
  :set ScriptUpdatesBaseUrl "https://127.0.0.1:1/";
  :set LanguageMessages ({});
  $LanguageUpdate;
  :if ([ $Translate "check-health.cpu.warning.subject" ] = "Health warning: CPU utilization") do={
    :error "Offline cached catalog failed";
  }
  /file/remove [ find where name=$Cache ];
  $LanguageUpdate;
  :if ([ $Translate "check-health.cpu.warning.subject" ] != "Health warning: CPU utilization") do={
    :error "Offline English fallback failed";
  }
  /file/add name=$Cache contents="{broken JSON";
  $LanguageUpdate;
  :if ([ $Translate "check-health.cpu.warning.subject" ] != "Health warning: CPU utilization") do={
    :error "Malformed cache fallback failed";
  }
  /file/set [ find where name=$Cache ] contents=$Cached;
  :set ($LanguageSchemas->"check-health") "outdated-schema";
  $LanguageUpdate;
  :if ([ $Translate "check-health.cpu.warning.subject" ] != "Health warning: CPU utilization") do={
    :error "Outdated schema fallback failed";
  }
  :set ScriptLanguage "../bad";
  $LanguageUpdate;
  :if ([ $Translate "check-health.cpu.warning.subject" ] != "Health warning: CPU utilization") do={
    :error "Invalid locale fallback failed";
  }
  /file/remove [ find where name=$Cache ];
  :put "Language download/cache tests passed.";
} do={
  /file/remove [ find where name=$Cache ];
  :error $LoaderError;
}
