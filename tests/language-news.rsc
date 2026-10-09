# Render the actual changelog with simulated hardware and a no-network updater.
:global LanguageUpdate;
:global LanguageSchemas;
:global LanguageMessages;
:global LanguageActive;
:global ScriptLanguage;
:global NewsFixtureRun;
:global NewsFixtureResource;
:global NewsFixturePortuguese;
:global NewsFixtureRefreshCount 0;
:global GlobalConfigChanges;
:global IDonate;
:local SavedUpdate $LanguageUpdate;
:set LanguageUpdate do={
  :global LanguageSchemas; :global NewsFixtureRefreshCount;
  :if ([ :len ($LanguageSchemas->"news-and-changes") ] != 64) do={ :error "Transient changelog schema missing"; }
  :set NewsFixtureRefreshCount ($NewsFixtureRefreshCount + 1);
};
:foreach Locale in={ "en"; "pt-BR" } do={
  :set ScriptLanguage $Locale;
  :set LanguageActive "pt-BR";
  :set LanguageMessages $NewsFixturePortuguese;
  :foreach Donates in={ false; true } do={
    :set IDonate $Donates;
    :foreach Space in={ "small"; "large"; "full" } do={
      :set NewsFixtureResource { "board-name"="VM"; "total-hdd-space"=10000000; "free-hdd-space"=1000000 };
      :if ($Space != "small") do={ :set ($NewsFixtureResource->"total-hdd-space") 100000000; }
      :if ($Space = "large") do={ :set ($NewsFixtureResource->"free-hdd-space") 5000000; }
      $NewsFixtureRun;
      :if ([ :len $GlobalConfigChanges ] != 51) do={ :error "Changelog entry count changed"; }
      :local Prefix "RouterOS packages increase in size";
      :local Affected "Your VM is specifically affected! ";
      :local Unaffected "(Your VM does not suffer this issue.) ";
      :local Thanks "Looks like you did donate already.";
      :local Request "Following the donation hint";
      :local Latest "Added multilingual notifications and diagnostics.";
      :if ($Locale = "pt-BR") do={
        :set Prefix "Os pacotes do RouterOS aumentam";
        :set Affected "Seu VM é especificamente afetado! ";
        :set Unaffected "(Seu VM não apresenta esse problema.) ";
        :set Thanks "Parece que você já fez uma doação.";
        :set Request "Seguir a sugestão de doação";
        :set Latest "Adicionadas notificações e diagnósticos em vários idiomas.";
      }
      :local Notice ($GlobalConfigChanges->"118");
      :if ([ :find $Notice $Prefix ] != 0) do={ :error "Translated storage notice failed"; }
      :if (($Space = "small") != ([ :typeof [ :find $Notice $Affected ] ] = "num")) do={ :error "Small-storage notice changed"; }
      :if (($Space = "large") != ([ :typeof [ :find $Notice $Unaffected ] ] = "num")) do={ :error "Free-storage notice changed"; }
      :local Donation ($GlobalConfigChanges->"116");
      :if ($Donates != ([ :typeof [ :find $Donation $Thanks ] ] = "num")) do={ :error "Donation thanks changed"; }
      :if ((!$Donates) != ([ :typeof [ :find $Donation $Request ] ] = "num")) do={ :error "Donation request changed"; }
      :if ([ :find ($GlobalConfigChanges->"146") $Latest ] != 0) do={ :error "New multilingual change note failed"; }
    }
  }
}
:if ($NewsFixtureRefreshCount != 12) do={ :error "Changelog language refresh missing"; }
:set LanguageUpdate $SavedUpdate;
:put "Transient changelog catalog and conditional news notifications passed.";
