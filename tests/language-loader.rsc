#!rsc by RouterOS
# Added by contrib/language-test.py --base-url in an isolated test bundle.
:global LanguageUpdate;
:global Translate;
:global LanguageSchemas;
:global ScriptLanguage;
:global ScriptUpdatesBaseUrl;
:global LanguageMessages;
:global LanguageActive;
:global LoaderFixtureSchemas;
:global GlobalNotReadyMessage;
:local PublishedBaseUrl $ScriptUpdatesBaseUrl;
:local ExtraCaches ({});

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
  :set ScriptUpdatesBaseUrl $PublishedBaseUrl;
  :set ScriptLanguage "pt-BR";
  :set LanguageSchemas $LoaderFixtureSchemas;
  :foreach Group,Schema in=$LanguageSchemas do={
    :local Name ($Prefix . "language-pt-BR-" . $Group . ".json");
    :if ([ :len [ /file/find where name=$Name ] ] > 0) do={ :error "Additional test cache already exists"; }
    :set ExtraCaches ($ExtraCaches, $Name);
  }
  $LanguageUpdate;
  :if ($GlobalNotReadyMessage != "Configuração e/ou funções globais não estão prontas.") do={
    :error "Translated bootstrap diagnostic failed";
  }
  :if ([ $Translate "core-extra.news.subject" ] != "Novidades e alterações de configuração") do={
    :error "Shared catalog download failed";
  }
  :if ([ :find [ $Translate "news-and-changes.146" ] "Adicionadas notificações" ] != 0) do={
    :error "Transient changelog catalog download failed";
  }
  :set ScriptUpdatesBaseUrl "https://127.0.0.1:1/";
  :set LanguageMessages ({});
  $LanguageUpdate;
  :if ($GlobalNotReadyMessage != "Configuração e/ou funções globais não estão prontas.") do={
    :error "Cached bootstrap diagnostic failed";
  }
  :set ScriptLanguage "en";
  $LanguageUpdate;
  :if ($GlobalNotReadyMessage != "Global config and/or functions not ready.") do={
    :error "English bootstrap diagnostic reset failed";
  }
  :foreach Name in=$ExtraCaches do={ /file/remove [ find where name=$Name ]; }
  :put "Language download/cache tests passed.";
} do={
  /file/remove [ find where name=$Cache ];
  :foreach Name in=$ExtraCaches do={ /file/remove [ find where name=$Name ]; }
  :error $LoaderError;
}
