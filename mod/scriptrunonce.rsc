#!rsc by RouterOS
# RouterOS script: mod/scriptrunonece
# Copyright (c) 2020-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# download script and run it once
# https://rsc.eworm.de/doc/mod/scriptrunonce.md

:global ScriptRunOnce;

# fetch and run script(s) once
:set ScriptRunOnce do={ :onerror Err {
  :local Scripts [ :toarray $1 ];

  :global ScriptRunOnceBaseUrl;
  :global ScriptRunOnceUrlSuffix;

  :global FetchHuge;
  :global LogPrint;
  :global ValidateSyntax;

  :foreach Script in=$Scripts do={
    :if (!($Script ~ "^(ftp|https?|sftp)://")) do={
      :if ([ :len $ScriptRunOnceBaseUrl ] = 0) do={
        $LogPrint warning $0 ("Script '" . $Script . "' is not an url and base url is not available.");
        :return false;
      }
      :set Script ($ScriptRunOnceBaseUrl . $Script . ".rsc" . $ScriptRunOnceUrlSuffix);
    }

    :local Source [ $FetchHuge $0 $Script true ];
    :if ($Source = false) do={
      $LogPrint warning $0 ("Failed fetching script '" . $Script . "'!");
      :return false;
    }

    :if ([ $ValidateSyntax $Source ] = false) do={
      $LogPrint warning $0 ("The script '" . $Script . "' failed syntax validation!");
      :return false;
    }

    :onerror Err {
      $LogPrint info $0 ("Running script '" . $Script . "' now.");
      [ :parse $Source ];
    } do={
      $LogPrint warning $0 ("The script '" . $Script . "' failed to run: " . $Err);
      :return false;
    }

    :return true;
  }
} do={
  :global ExitError; $ExitError false $0 $Err;
} }
