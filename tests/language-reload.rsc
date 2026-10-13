# Exercise refresh hooks from real sources; never reload the device configuration.
:global GlobalFunctionsReady;
:global LanguageUpdate;
:global ReloadFixtureConfig;
:global ReloadFixtureInstaller;
:global ReloadFixtureCount 0;
:local SavedUpdate $LanguageUpdate;
:local SavedReady $GlobalFunctionsReady;
:local ReadCount do={ :global ReloadFixtureCount; :return $ReloadFixtureCount; };
:foreach FunctionType in={ "array"; "code" } do={
  :set LanguageUpdate do={ :global ReloadFixtureCount; :set ReloadFixtureCount ($ReloadFixtureCount + 1); };
  :if ($FunctionType = "code") do={
    :set LanguageUpdate [ :parse ":global ReloadFixtureCount; :set ReloadFixtureCount (\$ReloadFixtureCount + 1);" ];
  }
  :set GlobalFunctionsReady false;
  :local Before [ $ReadCount ];
  $ReloadFixtureConfig;
  :delay 50ms;
  :if ([ $ReadCount ] != $Before) do={ :error "Configuration refreshed before functions were ready"; };
  :set GlobalFunctionsReady true;
  $ReloadFixtureConfig;
  :local Tries 0;
  :while ([ $ReadCount ] = $Before && $Tries < 50) do={ :delay 20ms; :set Tries ($Tries + 1); };
  :if ([ $ReadCount ] != ($Before + 1)) do={ :error ("Configuration language refresh failed: " . $FunctionType); };
  $ReloadFixtureInstaller;
  :if ([ $ReadCount ] != ($Before + 2)) do={ :error ("Installer language refresh failed: " . $FunctionType); };
}
:set GlobalFunctionsReady $SavedReady;
:set LanguageUpdate $SavedUpdate;
:put "Configuration and installer language refresh hooks passed for both function types.";
