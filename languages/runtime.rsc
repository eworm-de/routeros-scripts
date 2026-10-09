# Translation helpers. Embedded in global-functions.rsc by contrib/languages.py.
:global Translate;
:global LanguageUpdate;
:global LanguageEnglish;
:global LanguageMessages;
:global LanguageActive;

# Render placeholders once; parameter values are never evaluated or re-expanded.
:set Translate do={
  :local Key [ :tostr $1 ];
  :local Params $2;
  :global ScriptLanguage;
  :global LanguageEnglish;
  :global LanguageMessages;
  :global LanguageActive;

  :local English ($LanguageEnglish->$Key);
  :if ([ :typeof $English ] != "str") do={ :return $Key; }
  :local Text $English;
  :if ($LanguageActive = $ScriptLanguage && [ :typeof ($LanguageMessages->$Key) ] = "str") do={
    :set Text ($LanguageMessages->$Key);
  }
  :local Tokens do={
    :local Text $1;
    :local Names ({});
    :while ([ :len $Text ] > 0) do={
      :local Start [ :find $Text "{" ];
      :if ([ :typeof $Start ] = "nil") do={
        :if ([ :typeof [ :find $Text "}" ] ] != "nil") do={ :return false; }
        :return $Names;
      }
      :local End [ :find $Text "}" $Start ];
      :if ([ :typeof $End ] = "nil") do={ :return false; }
      :if ([ :typeof [ :find [ :pick $Text 0 $Start ] "}" ] ] != "nil") do={ :return false; }
      :local Name [ :pick $Text ($Start + 1) $End ];
      :if (!($Name ~ "^[a-z][a-z0-9_]*\$")) do={ :return false; }
      :set ($Names->$Name) true;
      :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
    }
    :return $Names;
  }
  :local EnglishTokens [ $Tokens $English ];
  :local TranslatedTokens [ $Tokens $Text ];
  :local Valid false;
  :if ([ :typeof $TranslatedTokens ] = "array" && \
       [ :len $EnglishTokens ] = [ :len $TranslatedTokens ]) do={
    :set Valid true;
    :foreach Name,Unused in=$EnglishTokens do={
      :if (($TranslatedTokens->$Name) != true) do={ :set Valid false; }
    }
  }
  :if ($Valid != true) do={ :set Text $English; }
  :local Result "";
  :while ([ :len $Text ] > 0) do={
    :local Start [ :find $Text "{" ];
    :if ([ :typeof $Start ] = "nil") do={ :return ($Result . $Text); }
    :local End [ :find $Text "}" $Start ];
    :if ([ :typeof $End ] = "nil") do={ :return $English; }
    :local Name [ :pick $Text ($Start + 1) $End ];
    :if ([ :typeof ($Params->$Name) ] = "nothing" || \
         [ :typeof ($Params->$Name) ] = "nil") do={ :return $English; }
    :set Result ($Result . [ :pick $Text 0 $Start ] . [ :tostr ($Params->$Name) ]);
    :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
  }
  :return $Result;
}

# Load a cached catalog before fetching. Never run downloaded text as code.
:set LanguageUpdate do={
  :global Translate;
  :global GlobalNotReadyMessage;
  :global ScriptLanguage;
  :global ScriptUpdatesBaseUrl;
  :global ScriptUpdatesUrlSuffix;
  :global LanguageSchemas;
  :global LanguageMessages;
  :global LanguageActive;
  :global LanguageUpdateRunning;

  :if ($LanguageUpdateRunning = true) do={ :return false; }
  :set LanguageUpdateRunning true;
  :local Locale $ScriptLanguage;
  :onerror Err {
    :if ($Locale = "en") do={
      :set LanguageMessages ({});
      :set LanguageActive "en";
      :set GlobalNotReadyMessage [ $Translate "global-config.not.ready" ];
      :set LanguageUpdateRunning false;
      :return true;
    }
    :if (!($Locale ~ "^[a-z][a-z](-[A-Z][A-Z])?\$")) do={
      :error [ $Translate "global-functions.language.invalid" ];
    }
    :if ([ :pick $ScriptUpdatesBaseUrl 0 8 ] != "https://") do={
      :error [ $Translate "global-functions.language.https" ];
    }
    :local ReadCatalog do={
      :global Translate;
      :local Body $1;
      :local Schema $2;
      :local Locale $3;
      :local Group $4;
      :if ([ :len $Body ] > 50000) do={ :error [ $Translate "global-functions.language.size" ]; }
      :local Catalog [ :deserialize from=json options=json.no-string-conversion $Body ];
      :if (($Catalog->"schema") != $Schema || ($Catalog->"language") != $Locale || \
           [ :typeof ($Catalog->"messages") ] != "array") do={
        :error [ $Translate "global-functions.language.incompatible" ];
      }
      :foreach Key,Value in=($Catalog->"messages") do={
        :if ([ :typeof $Value ] != "str" || \
             [ :pick $Key 0 ([ :len $Group ] + 1) ] != ($Group . ".")) do={
          :error [ $Translate "global-functions.language.message.invalid" ];
        }
      }
      :return ($Catalog->"messages");
    }
    :local AllMessages ({});
    :local Prefix "";
    :if ([ :len [ /file/find where name="flash" ] ] > 0) do={ :set Prefix "flash/"; }
    :foreach Group,Schema in=$LanguageSchemas do={
      :local Cache ($Prefix . "language-" . $Locale . "-" . $Group . ".json");
      :local Messages ({});
      :local Cached "";
      :local Files [ /file/find where name=$Cache ];
      :if ([ :len $Files ] = 1) do={
        :do {
          :set Cached [ /file/get $Files contents ];
          :set Messages [ $ReadCatalog $Cached $Schema $Locale $Group ];
        } on-error={ :set Cached ""; }
      }
      # Make cached text available while the network request is in progress.
      :foreach Key,Value in=$Messages do={ :set ($AllMessages->$Key) $Value; }
      :if ($ScriptLanguage = $Locale) do={
        :set LanguageMessages $AllMessages;
        :set LanguageActive $Locale;
      }
      :onerror FetchErr {
        :local Url ($ScriptUpdatesBaseUrl . "languages/" . $Locale . "/" . $Group . ".json" . $ScriptUpdatesUrlSuffix);
        :local Response [ /tool/fetch url=$Url check-certificate=yes-without-crl output=user as-value ];
        :if (($Response->"status") != "finished") do={ :error [ $Translate "global-functions.language.incomplete" ]; }
        :local Body ($Response->"data");
        :local NewMessages [ $ReadCatalog $Body $Schema $Locale $Group ];
        :set Messages $NewMessages;
        :if ($Body != $Cached) do={
          :do {
            :if ([ :len $Files ] = 0) do={
              /file/add name=$Cache contents=$Body;
            } else={ /file/set $Files contents=$Body; }
          } on-error={ :log warning [ $Translate "global-functions.language.cache.failed" ]; }
        }
      } do={
        :log warning [ $Translate "global-functions.language.fetch.failed" ({ group=$Group; error=$FetchErr }) ];
      }
      :foreach Key,Value in=$Messages do={ :set ($AllMessages->$Key) $Value; }
    }
    :if ($ScriptLanguage = $Locale) do={
      :set LanguageMessages $AllMessages;
      :set LanguageActive $Locale;
    }
  } do={ :log warning [ $Translate "global-functions.language.update.failed" ({ error=$Err }) ]; }
  :set GlobalNotReadyMessage [ $Translate "global-config.not.ready" ];
  :set LanguageUpdateRunning false;
  :return true;
}
