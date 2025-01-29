#!rsc by RouterOS
# RouterOS script: mod/scriptrunonece
# Copyright (c) 2020-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.14
# requires device-mode, fetch
#
# download script and run it once
# https://rsc.eworm.de/doc/mod/scriptrunonce.md

:global ScriptRunOnce;

# fetch and run script(s) once
:set ScriptRunOnce do={ :do {
  :local Scripts [ :toarray $1 ];

  :global ScriptRunOnceBaseUrl;
  :global ScriptRunOnceUrlSuffix;

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

    :local Source;
    :do {    
      :set Source ([ /tool/fetch check-certificate=yes-without-crl $Script output=user as-value ]->"data");
    } on-error={
      $LogPrint warning $0 ("Failed fetching script '" . $Script . "'!");
    }

    :if ([ :len $Source ] > 0) do={
      :if ([ $ValidateSyntax $Source ] = true) do={
        :do {
          $LogPrint info $0 ("Running script '" . $Script . "' now.");
          [ :parse $Source ];
        } on-error={
          $LogPrint warning $0 ("The script '" . $Script . "' failed to run!");
        }
      } else={
        $LogPrint warning $0 ("The script '" . $Script . "' failed syntax validation!");
      }
    }
  }
} on-error={
  :global ExitError; $ExitError false $0;
} }
