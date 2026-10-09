#!rsc by RouterOS
# RouterOS script: mod/scriptrunonece
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# download script and run it once
# https://rsc.eworm.de/doc/mod/scriptrunonce.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=scriptrunonce, schema=60deac34267f7cfb590d500ce671562bfd8cf79337f433f8b350281561a4ae52
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"scriptrunonce.failed") "The script '{script}' failed to run: {error}";
:set ($LanguageEnglish->"scriptrunonce.fetch.failed") "Failed fetching script '{script}'!";
:set ($LanguageEnglish->"scriptrunonce.running") "Running script '{script}' now.";
:set ($LanguageEnglish->"scriptrunonce.syntax") "The script '{script}' failed syntax validation!";
:set ($LanguageEnglish->"scriptrunonce.url.missing") "Script '{script}' is not an url and base url is not available.";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:global ScriptRunOnce;

# fetch and run script(s) once
:set ScriptRunOnce do={ :onerror Err {
  :local Scripts [ :toarray $1 ];

  :global ScriptRunOnceBaseUrl;
  :global ScriptRunOnceUrlSuffix;

  :global FetchHuge;
  :global LogPrint;
  :global Translate;
  :global ValidateSyntax;

  :foreach Script in=$Scripts do={
    :if (!($Script ~ "^(ftp|https?|sftp)://")) do={
      :if ([ :len $ScriptRunOnceBaseUrl ] = 0) do={
        $LogPrint warning $0 [ $Translate "scriptrunonce.url.missing" ({ script=$Script }) ];
        :return false;
      }
      :set Script ($ScriptRunOnceBaseUrl . $Script . ".rsc" . $ScriptRunOnceUrlSuffix);
    }

    :local Source [ $FetchHuge $0 $Script true ];
    :if ($Source = false) do={
      $LogPrint warning $0 [ $Translate "scriptrunonce.fetch.failed" ({ script=$Script }) ];
      :return false;
    }

    :if ([ $ValidateSyntax $Source ] = false) do={
      $LogPrint warning $0 [ $Translate "scriptrunonce.syntax" ({ script=$Script }) ];
      :return false;
    }

    :onerror Err {
      $LogPrint info $0 [ $Translate "scriptrunonce.running" ({ script=$Script }) ];
      [ :parse $Source ];
    } do={
      $LogPrint warning $0 [ $Translate "scriptrunonce.failed" ({ script=$Script; error=$Err }) ];
      :return false;
    }

    :return true;
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }
