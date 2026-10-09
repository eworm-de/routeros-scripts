# Real bootstrap/state logic, isolated script names and simulated fetch responses.
:global CoreFixtureSource;
:global CoreFixtureModuleSource;
:global CoreFixtureStatus "finished";
:global CoreFixtureBody;
:global CoreFixtureFetchCount 0;
:global CoreFixtureOffline false;
:global CoreFixtureFetch do={
  :global CoreFixtureBody; :global CoreFixtureStatus;
  :global CoreFixtureFetchCount; :global CoreFixtureOffline;
  :set CoreFixtureFetchCount ($CoreFixtureFetchCount + 1);
  :if ($CoreFixtureOffline = true) do={ :error "Fixture is offline"; };
  :return { "status"=$CoreFixtureStatus; "data"=$CoreFixtureBody };
}
:global ScriptLanguage "en";
:global ScriptUpdatesBaseUrl "https://example.invalid/";
:global ScriptUpdatesUrlSuffix "";
:global PrintDebug false;
:global PrintDebugOverride false;
:global GlobalFunctionsReady;
:local ReadReady do={ :global GlobalFunctionsReady; :return $GlobalFunctionsReady; };
:local ReadFetchCount do={ :global CoreFixtureFetchCount; :return $CoreFixtureFetchCount; };
:local ReadFunctions do={
  :global ScriptInstallUpdate; :global SymbolForNotification;
  :global DeviceInfo; :global DownloadPackage; :global GetMacVendor;
  :return ([ :typeof $ScriptInstallUpdate ] = "array" && [ :typeof $SymbolForNotification ] = "array" && \
           [ :typeof $DeviceInfo ] = "array" && [ :typeof $DownloadPackage ] = "array" && [ :typeof $GetMacVendor ] = "array");
}
:if ([ :len [ /system/script/find where name="LanguageTestCoreExtra" ] ] > 0) do={ :error "Refusing to overwrite a core test script"; };
:onerror FixtureError {
  # Simulate upgrading from the old monolithic core: dependency not installed.
  :set CoreFixtureBody $CoreFixtureModuleSource;
  [ :parse $CoreFixtureSource ];
  :delay 50ms;
  :if ([ $ReadReady ] != true || [ $ReadFunctions ] != true || [ $ReadFetchCount ] != 1) do={ :error "Core dependency bootstrap failed"; };
  :local Module [ /system/script/find where name="LanguageTestCoreExtra" ];
  :if ([ :len $Module ] != 1) do={ :error "Core module was not installed exactly once"; };

  # Offline startup uses the installed source, including a CRLF installation.
  /system/script/set source=[ :tocrlf $CoreFixtureModuleSource ] $Module;
  :set CoreFixtureOffline true;
  [ :parse $CoreFixtureSource ];
  :delay 50ms;
  :if ([ $ReadReady ] != true || [ $ReadFetchCount ] != 1) do={ :error "Offline core startup fetched the module"; };

  # A stale API is replaced, then executed only after validation.
  :set CoreFixtureOffline false;
  /system/script/set source="#!rsc by RouterOS\n# core-module, version=9\n:nothing;\n" $Module;
  [ :parse $CoreFixtureSource ];
  :delay 50ms;
  :if ([ $ReadReady ] != true || [ $ReadFetchCount ] != 2) do={ :error "Stale core API was not replaced"; };
  :if ([ :tolf [ /system/script/get $Module source ] ] != $CoreFixtureModuleSource) do={ :error "Core source replacement failed"; };
  /system/script/remove $Module;

  :foreach Failure in={ "offline"; "status"; "schema"; "syntax"; "exports" } do={
    :set CoreFixtureBody $CoreFixtureModuleSource;
    :set CoreFixtureStatus "finished";
    :set CoreFixtureOffline false;
    :if ($Failure = "offline") do={ :set CoreFixtureOffline true; };
    :if ($Failure = "status") do={ :set CoreFixtureStatus "failed"; };
    :if ($Failure = "schema") do={ :set CoreFixtureBody "#!rsc by RouterOS\n# requires RouterOS, version=7.22\n# core-module, version=9\n:nothing;\n"; };
    :if ($Failure = "syntax") do={ :set CoreFixtureBody "#!rsc by RouterOS\n# requires RouterOS, version=7.22\n# core-module, version=1\n:local Broken {\n"; };
    :if ($Failure = "exports") do={ :set CoreFixtureBody "#!rsc by RouterOS\n# requires RouterOS, version=7.22\n# core-module, version=1\n:nothing;\n"; };
    :local Failed false;
    :onerror ExpectedError { [ :parse $CoreFixtureSource ]; } do={ :set Failed true; };
    :if ($Failed != true || [ $ReadReady ] != false || [ :len [ /system/script/find where name="LanguageTestCoreExtra" ] ] != 0) do={ :error ("Invalid core dependency was accepted: " . $Failure); };
  }
} do={
  /system/script/remove [ /system/script/find where name="LanguageTestCoreExtra" ];
  :error $FixtureError;
}
/system/script/remove [ /system/script/find where name="LanguageTestCoreExtra" ];
:put "Required core dependency, offline startup and validation failure tests passed.";
