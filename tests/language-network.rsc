# Simulate reads, then stop bridge functions at their existing DHCP guards.
:global GlobalConfigReady true;
:global GlobalFunctionsReady true;
:global ScriptLock do={ :return true; };
:global WaitFullyConnected do={};
:global CertificateAvailable do={ :return false; };
:global FetchHuge do={ :return "#"; };
:global ParseKeyValueStore do={ :return { "home"="dhcp-client" }; };
:global BridgeFixturePort { "interface"="fixture-interface"; "comment"="home=dhcp-client" };
:global BridgeFixtureClients;
:global BridgePortTo;
:global BridgePortVlan;
:global FirewallFixtureRun;
:global FwAddrListTimeOut 1h;
:global FwAddrLists { "fixture-list"={ { "url"="https://example.invalid/"; "cert"="fixture-root" } } };
:global CapturedMessages;
:global CapturedCount;
:global LogPrint do={
  :global CapturedMessages; :global CapturedCount;
  :set ($CapturedMessages->[ :tostr $CapturedCount ]) $3;
  :set CapturedCount ($CapturedCount + 1);
}
:global LogPrintVerbose do={ :error "Unexpected firewall address operation"; };
:global ExitOnError do={ :error $2; };
:global ScriptLanguage;
:global LanguageActive;

:foreach Locale in={ "en"; "pt-BR" } do={
  :set ScriptLanguage $Locale;
  :set LanguageActive "pt-BR";
  :foreach Function in={ "bridge"; "vlan" } do={
    :foreach Count in={ 0; 2 } do={
      :set BridgeFixtureClients ({});
      :if ($Count = 2) do={ :set BridgeFixtureClients { "one"; "two" }; };
      :set CapturedMessages ({});
      :set CapturedCount 0;
      :local Result;
      :if ($Function = "bridge") do={ :set Result [ $BridgePortTo "home" ]; } else={ :set Result [ $BridgePortVlan "home" ]; };
      # These existing functions return the onerror result plus the guard value.
      :if (($Result->1) != false) do={ :error "Bridge DHCP guard failed"; };
      :local Expected "Missing dhcp client configuration for interface fixture-interface!";
      :if ($Count = 2) do={ :set Expected "Duplicate dhcp client configuration for interface fixture-interface!"; };
      :if ($Locale = "pt-BR") do={
        :set Expected "Configura\C3\A7\C3\A3o do cliente DHCP ausente para a interface fixture-interface!";
        :if ($Count = 2) do={ :set Expected "Configura\C3\A7\C3\A3o duplicada do cliente DHCP para a interface fixture-interface!"; };
      }
      :if ($CapturedCount != 1 || ($CapturedMessages->"0") != $Expected) do={ :error "Bridge guard diagnostic failed"; };
    }
  }
  :set CapturedMessages ({});
  :set CapturedCount 0;
  $FirewallFixtureRun;
  :local Expected "Downloading required certificate (fixture-list / https://example.invalid/) failed, trying anyway.";
  :local Summary "list: fixture-list (0) -- added: 0 - renewed: 0 - removed: 0";
  :if ($Locale = "pt-BR") do={
    :set Expected "Falha ao baixar o certificado necess\C3\A1rio (fixture-list / https://example.invalid/); tentando mesmo assim.";
    :set Summary "lista: fixture-list (0) -- adicionados: 0 - renovados: 0 - removidos: 0";
  }
  :if ($CapturedCount != 3 || ($CapturedMessages->"0") != $Expected || ($CapturedMessages->"2") != $Summary) do={ :error "Firewall list diagnostics failed"; };
}
:put "Simulated firewall diagnostics and bridge DHCP guards passed.";
