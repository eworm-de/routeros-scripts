#!rsc by RouterOS
# RouterOS script: mod/scriptrunonece
# Copyright (c) 2020-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# download script and run it once
# https://git.eworm.de/cgit/routeros-scripts/about/doc/mod/scriptrunonce.md

:global ScriptRunOnce;

# fetch and run script(s) once
:set ScriptRunOnce do={
  :local Scripts [ :toarray $1 ];

  :global ScriptRunOnceBaseUrl;
  :global ScriptRunOnceUrlSuffix;

  :global LogPrintExit2;
  :global ValidateSyntax;

  :foreach Script in=$Scripts do={
    :if (!($Script ~ "^(ftp|https\?|sftp)://")) do={
      :if ([ :len $ScriptRunOnceBaseUrl ] = 0) do={
        $LogPrintExit2 warning $0 ("Script '" . $Script . "' is not an url and base url is not available.") true;
      }
      :set Script ($ScriptRunOnceBaseUrl . $Script . ".rsc" . $ScriptRunOnceUrlSuffix);
    }

    :local Source;
    :do {    
      :set Source ([ /tool/fetch check-certificate=yes-without-crl $Script output=user as-value ]->"data");
    } on-error={
      $LogPrintExit2 warning $0 ("Failed fetching script '" . $Script . "'!") false;
    }

    :if ([ :len $Source ] > 0) do={
      :if ([ $ValidateSyntax $Source ] = true) do={
        :do {
          $LogPrintExit2 info $0 ("Running script '" . $Script . "' now.") false;
          [ :parse $Source ];
        } on-error={
          $LogPrintExit2 warning $0 ("The script '" . $Script . "' failed to run!") false;
        }
      } else={
        $LogPrintExit2 warning $0 ("The script '" . $Script . "' failed syntax validation!") false;
      }
    }
  }
}
