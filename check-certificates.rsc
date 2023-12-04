#!rsc by RouterOS
# RouterOS script: check-certificates
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# check for certificate validity
# https://git.eworm.de/cgit/routeros-scripts/about/doc/check-certificates.md

:local 0 "check-certificates";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global CertRenewTime;
:global CertRenewUrl;
:global CertWarnTime;
:global Identity;

:global CertificateAvailable
:global EscapeForRegEx;
:global IfThenElse;
:global LogPrintExit2;
:global ParseKeyValueStore;
:global ScriptLock;
:global SendNotification2;
:global SymbolForNotification;
:global UrlEncode;
:global WaitFullyConnected;

:local CheckCertificatesDownloadImport do={
  :local Name [ :tostr $1 ];

  :global CertRenewUrl;
  :global CertRenewPass;

  :global CertificateNameByCN;
  :global EscapeForRegEx;
  :global LogPrintExit2;
  :global UrlEncode;
  :global WaitForFile;

  :local Return false;

  :foreach Type in={ ".pem"; ".p12" } do={
    :local CertFileName ([ $UrlEncode $Name ] . $Type);
    :do {
      /tool/fetch check-certificate=yes-without-crl \
          ($CertRenewUrl . $CertFileName) dst-path=$CertFileName as-value;
      $WaitForFile $CertFileName;

      :local DecryptionFailed true;
      :foreach PassPhrase in=$CertRenewPass do={
        :local Result [ /certificate/import file-name=$CertFileName passphrase=$PassPhrase as-value ];
        :if ($Result->"decryption-failures" = 0) do={
          :set DecryptionFailed false;
        }
      }
      /file/remove [ find where name=$CertFileName ];

      :if ($DecryptionFailed = true) do={
        $LogPrintExit2 warning $0 ("Decryption failed for certificate file " . $CertFileName) false;
      }

      :foreach CertInChain in=[ /certificate/find where name~("^" . [ $EscapeForRegEx $CertFileName ] . "_[0-9]+\$") \
          common-name!=$Name !(subject-alt-name~("(^|\\W)(DNS|IP):" . [ $EscapeForRegEx $Name ] . "(\\W|\$)")) !(common-name=[]) ] do={
        $CertificateNameByCN [ /certificate/get $CertInChain common-name ];
      }

      :set Return true;
    } on-error={
      $LogPrintExit2 debug $0 ("Could not download certificate file " . $CertFileName) false;
    }
  }

  :return $Return;
}

:local FormatInfo do={
  :local Cert $1;

  :global FormatLine;
  :global FormatMultiLines;
  :global IfThenElse;
  :global EitherOr;

  :local FormatExpire do={
    :global CharacterReplace;
    :return [ $CharacterReplace [ $CharacterReplace [ :tostr $1 ] "w" "w " ] "d" "d " ];
  }

  :local FormatCertChain do={
    :local Cert $1;

    :global ParseKeyValueStore;

    :local CertVal [ /certificate/get $Cert ];
    :local Return "";

    :for I from=0 to=3 do={
      :set Return ($Return . [ $ParseKeyValueStore ($CertVal->"issuer") ]->"CN");
      :if (($CertVal->"akid") = "" || ($CertVal->"akid") = ($CertVal->"skid")) do={
        :return $Return;
      }
      :set Return ($Return . " -> ");
      :set CertVal [ /certificate/get [ find where skid=($CertVal->"akid") ] ];
    }
    :return ($Return . "...");
  }

  :local CertVal [ /certificate/get $Cert ];

  :return ( \
    [ $FormatLine "Name" ($CertVal->"name") ] . "\n" . \
    [ $IfThenElse ([ :len ($CertVal->"common-name") ] > 0) ([ $FormatLine "CommonName" ($CertVal->"common-name") ] . "\n") ] . \
    [ $IfThenElse ([ :len ($CertVal->"subject-alt-name") ] > 0) ([ $FormatMultiLines "SubjectAltNames" ($CertVal->"subject-alt-name") ] . "\n") ] . \
    [ $FormatLine "Private key" [ $IfThenElse (($CertVal->"private-key") = true) "available" "missing" ] ] . "\n" . \
    [ $FormatLine "Fingerprint" ($CertVal->"fingerprint") ] . "\n" . \
    [ $FormatLine "Issuer" [ $EitherOr ($CertVal->"ca") [ $FormatCertChain $Cert ] ] ] . "\n" . \
    "Validity:\n" . \
    [ $FormatLine "    from" ($CertVal->"invalid-before") ] . "\n" . \
    [ $FormatLine "    to" ($CertVal->"invalid-after") ] . "\n" . \
    [ $FormatLine "Expires in" [ $IfThenElse (($CertVal->"expired") = true) "expired" [ $FormatExpire ($CertVal->"expires-after") ] ] ]);
}

$ScriptLock $0;
$WaitFullyConnected;

:foreach Cert in=[ /certificate/find where !revoked !ca !scep-url expires-after<$CertRenewTime ] do={
  :local CertVal [ /certificate/get $Cert ];
  :local CertNew;
  :local LastName;

  :do {
    :if ([ :len $CertRenewUrl ] = 0) do={
      $LogPrintExit2 info $0 ("No CertRenewUrl given.") true;
    }
    $LogPrintExit2 info $0 ("Attempting to renew certificate " . ($CertVal->"name") . ".") false;

    :local ImportSuccess false;
    :set LastName ($CertVal->"common-name");
    :set ImportSuccess [ $CheckCertificatesDownloadImport $LastName ];
    :foreach SAN in=($CertVal->"subject-alt-name") do={
      :if ($ImportSuccess = false) do={
        :set LastName [ :pick $SAN ([ :find $SAN ":" ] + 1) [ :len $SAN ] ];
        :set ImportSuccess [ $CheckCertificatesDownloadImport $LastName ];
      }
    }

    :if ($CertVal->"fingerprint" != [ /certificate/get $Cert fingerprint ]) do={
      $LogPrintExit2 debug $0 ("Certificate '" . $CertVal->"name" . "' was updated in place.") false;
      :set CertVal [ /certificate/get $Cert ];
    } else={
      $LogPrintExit2 debug $0 ("Certificate '" . $CertVal->"name" . "' was not updated, but replaced.") false;

      :set CertNew [ /certificate/find where name~("^" . [ $EscapeForRegEx [ $UrlEncode $LastName ] ] . "\\.(p12|pem)_[0-9]+\$") \
        (common-name=($CertVal->"common-name") or subject-alt-name~("(^|\\W)(DNS|IP):" . [ $EscapeForRegEx $LastName ] . "(\\W|\$)")) \
        fingerprint!=[ :tostr ($CertVal->"fingerprint") ] expires-after>$CertRenewTime ];
      :local CertNewVal [ /certificate/get $CertNew ];

      :if ([ $CertificateAvailable ([ $ParseKeyValueStore ($CertNewVal->"issuer") ]->"CN") ] = false) do={
        $LogPrintExit2 warning $0 ("The certificate chain is not available!") false;
      }

      :if (($CertVal->"private-key") = true && ($CertVal->"private-key") != ($CertNewVal->"private-key")) do={
        /certificate/remove $CertNew;
        $LogPrintExit2 warning $0 ("Old certificate '" . ($CertVal->"name") . "' has a private key, new certificate does not. Aborting renew.") true;
      }

      /ip/service/set certificate=($CertNewVal->"name") [ find where certificate=($CertVal->"name") ];

      /ip/ipsec/identity/set certificate=($CertNewVal->"name") [ find where certificate=($CertVal->"name") ];
      /ip/ipsec/identity/set remote-certificate=($CertNewVal->"name") [ find where remote-certificate=($CertVal->"name") ];

      /ip/hotspot/profile/set ssl-certificate=($CertNewVal->"name") [ find where ssl-certificate=($CertVal->"name") ];

      /certificate/remove $Cert;
      /certificate/set $CertNew name=($CertVal->"name");
      :set CertNewVal;
      :set CertVal [ /certificate/get $CertNew ];
    }

    $SendNotification2 ({ origin=$0; silent=true; \
      subject=([ $SymbolForNotification "lock-with-ink-pen" ] . "Certificate renewed: " . ($CertVal->"name")); \
      message=("A certificate on " . $Identity . " has been renewed.\n\n" . [ $FormatInfo $CertNew ]) });
    $LogPrintExit2 info $0 ("The certificate " . ($CertVal->"name") . " has been renewed.") false;
  } on-error={
    $LogPrintExit2 debug $0 ("Could not renew certificate " . ($CertVal->"name") . ".") false;
  }
}

:foreach Cert in=[ /certificate/find where !revoked !scep-url !(expires-after=[]) \
                   expires-after<$CertWarnTime !(fingerprint=[]) ] do={
  :local CertVal [ /certificate/get $Cert ];

  :if ([ :len [ /certificate/scep-server/find where ca-cert=($CertVal->"ca") ] ] > 0) do={
    $LogPrintExit2 debug $0 ("Certificate \"" . ($CertVal->"name") . "\" is handled by SCEP, skipping.") false;
  } else={
    :local State [ $IfThenElse (($CertVal->"expired") = true) "expired" "is about to expire" ];

    $SendNotification2 ({ origin=$0; \
      subject=([ $SymbolForNotification "warning-sign" ] . "Certificate warning: " . ($CertVal->"name")); \
      message=("A certificate on " . $Identity . " " . $State . ".\n\n" . [ $FormatInfo $Cert ]) });
    $LogPrintExit2 info $0 ("The certificate " . ($CertVal->"name") . " " . $State . \
        ", it is invalid after " . ($CertVal->"invalid-after") . ".") false;
  }
}
