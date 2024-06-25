#!rsc by RouterOS
# RouterOS script: check-certificates
# Copyright (c) 2013-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.13
#
# check for certificate validity
# https://git.eworm.de/cgit/routeros-scripts/about/doc/check-certificates.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:do {
  :local ScriptName [ :jobname ];

  :global CertRenewTime;
  :global CertRenewUrl;
  :global CertWarnTime;
  :global Identity;

  :global CertificateAvailable
  :global EscapeForRegEx;
  :global IfThenElse;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global UrlEncode;
  :global WaitFullyConnected;

  :local CheckCertificatesDownloadImport do={
    :local ScriptName [ :tostr $1 ];
    :local Name       [ :tostr $2 ];

    :global CertRenewUrl;
    :global CertRenewPass;

    :global CertificateNameByCN;
    :global EscapeForRegEx;
    :global FetchUserAgentStr;
    :global LogPrint;
    :global UrlEncode;
    :global WaitForFile;

    :local Return false;

    :foreach Type in={ ".pem"; ".p12" } do={
      :local CertFileName ([ $UrlEncode $Name ] . $Type);
      :do {
        /tool/fetch check-certificate=yes-without-crl http-header-field=({ [ $FetchUserAgentStr $ScriptName ] }) \
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
          $LogPrint warning $ScriptName ("Decryption failed for certificate file '" . $CertFileName . "'.");
        }

        :foreach CertInChain in=[ /certificate/find where name~("^" . [ $EscapeForRegEx $CertFileName ] . "_[0-9]+\$") \
            common-name!=$Name !(subject-alt-name~("(^|\\W)(DNS|IP):" . [ $EscapeForRegEx $Name ] . "(\\W|\$)")) !(common-name=[]) ] do={
          $CertificateNameByCN [ /certificate/get $CertInChain common-name ];
        }

        :set Return true;
      } on-error={
        $LogPrint debug $ScriptName ("Could not download certificate file '" . $CertFileName . "'.");
      }
    }

    :return $Return;
  }

  :local FormatInfo do={
    :local Cert $1;

    :global FormatLine;
    :global FormatMultiLines;
    :global IfThenElse;

    :local FormatExpire do={
      :global CharacterReplace;
      :return [ $CharacterReplace [ $CharacterReplace [ :tostr $1 ] "w" "w " ] "d" "d " ];
    }

    :local FormatCertChain do={
      :local Cert $1;

      :global EitherOr;
      :global ParseKeyValueStore;

      :local CertVal [ /certificate/get $Cert ];

      :if ([ :typeof ($CertVal->"issuer") ] = "nothing") do={
        :return "self-signed";
      }

      :local Return "";
      :for I from=0 to=5 do={
        :set Return ($Return . [ $EitherOr ([ $ParseKeyValueStore ($CertVal->"issuer") ]->"CN") \
          ([ $ParseKeyValueStore (($CertVal->"issuer")->0) ]->"CN") ]);
        :set CertVal [ /certificate/get [ find where skid=($CertVal->"akid") ] ];
        :if (($CertVal->"akid") = "" || ($CertVal->"akid") = ($CertVal->"skid")) do={
          :return $Return;
        }
        :set Return ($Return . " -> ");
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
      [ $IfThenElse ([ :len ($CertVal->"ca") ] > 0) [ $FormatLine "Issuer" ($CertVal->"ca") ] [ $FormatLine "Issuer chain" [ $FormatCertChain $Cert ] ] ] . "\n" . \
      "Validity:\n" . \
      [ $FormatLine "    from" ($CertVal->"invalid-before") ] . "\n" . \
      [ $FormatLine "    to" ($CertVal->"invalid-after") ] . "\n" . \
      [ $FormatLine "Expires in" [ $IfThenElse (($CertVal->"expired") = true) "expired" [ $FormatExpire ($CertVal->"expires-after") ] ] ]);
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :error false;
  }
  $WaitFullyConnected;

  :foreach Cert in=[ /certificate/find where !revoked !ca !scep-url expires-after<$CertRenewTime ] do={
    :local CertVal [ /certificate/get $Cert ];
    :local LastName;

    :do {
      :if ([ :len $CertRenewUrl ] = 0) do={
        $LogPrint info $ScriptName ("No CertRenewUrl given.");
        :error false;
      }
      $LogPrint info $ScriptName ("Attempting to renew certificate '" . ($CertVal->"name") . "'.");

      :local ImportSuccess false;
      :set LastName ($CertVal->"common-name");
      :set ImportSuccess [ $CheckCertificatesDownloadImport $ScriptName $LastName ];
      :foreach SAN in=($CertVal->"subject-alt-name") do={
        :if ($ImportSuccess = false) do={
          :set LastName [ :pick $SAN ([ :find $SAN ":" ] + 1) [ :len $SAN ] ];
          :set ImportSuccess [ $CheckCertificatesDownloadImport $ScriptName $LastName ];
        }
      }
      :if ($ImportSuccess = false) do={ :error false; }

      :if ([ :len ($CertVal->"fingerprint") ] > 0 && $CertVal->"fingerprint" != [ /certificate/get $Cert fingerprint ]) do={
        $LogPrint debug $ScriptName ("Certificate '" . $CertVal->"name" . "' was updated in place.");
        :set CertVal [ /certificate/get $Cert ];
      } else={
        $LogPrint debug $ScriptName ("Certificate '" . $CertVal->"name" . "' was not updated, but replaced.");

        :local CertNew [ /certificate/find where name~("^" . [ $EscapeForRegEx [ $UrlEncode $LastName ] ] . "\\.(p12|pem)_[0-9]+\$") \
          (common-name=($CertVal->"common-name") or subject-alt-name~("(^|\\W)(DNS|IP):" . [ $EscapeForRegEx $LastName ] . "(\\W|\$)")) \
          fingerprint!=[ :tostr ($CertVal->"fingerprint") ] expires-after>$CertRenewTime ];
        :local CertNewVal [ /certificate/get $CertNew ];

        :if ([ $CertificateAvailable ([ $ParseKeyValueStore ($CertNewVal->"issuer") ]->"CN") ] = false) do={
          $LogPrint warning $ScriptName ("The certificate chain is not available!");
        }

        :if (($CertVal->"private-key") = true && ($CertVal->"private-key") != ($CertNewVal->"private-key")) do={
          /certificate/remove $CertNew;
          $LogPrint warning $ScriptName ("Old certificate '" . ($CertVal->"name") . "' has a private key, new certificate does not. Aborting renew.");
          :error false;
        }

        /ip/service/set certificate=($CertNewVal->"name") [ find where certificate=($CertVal->"name") ];

        /ip/ipsec/identity/set certificate=($CertNewVal->"name") [ find where certificate=($CertVal->"name") ];
        /ip/ipsec/identity/set remote-certificate=($CertNewVal->"name") [ find where remote-certificate=($CertVal->"name") ];

        /ip/hotspot/profile/set ssl-certificate=($CertNewVal->"name") [ find where ssl-certificate=($CertVal->"name") ];

        /certificate/remove $Cert;
        /certificate/set $CertNew name=($CertVal->"name");
        :set Cert $CertNew;
        :set CertVal [ /certificate/get $CertNew ];
      }

      $SendNotification2 ({ origin=$ScriptName; silent=true; \
        subject=([ $SymbolForNotification "lock-with-ink-pen" ] . "Certificate renewed: " . ($CertVal->"name")); \
        message=("A certificate on " . $Identity . " has been renewed.\n\n" . [ $FormatInfo $Cert ]) });
      $LogPrint info $ScriptName ("The certificate '" . ($CertVal->"name") . "' has been renewed.");
    } on-error={
      $LogPrint debug $ScriptName ("Could not renew certificate '" . ($CertVal->"name") . "'.");
    }
  }

  :foreach Cert in=[ /certificate/find where !revoked !scep-url !(expires-after=[]) \
                     expires-after<$CertWarnTime !(fingerprint=[]) ] do={
    :local CertVal [ /certificate/get $Cert ];

    :if ([ :len [ /certificate/scep-server/find where ca-cert=($CertVal->"ca") ] ] > 0) do={
      $LogPrint debug $ScriptName ("Certificate '" . ($CertVal->"name") . "' is handled by SCEP, skipping.");
    } else={
      :local State [ $IfThenElse (($CertVal->"expired") = true) "expired" "is about to expire" ];

      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "warning-sign" ] . "Certificate warning: " . ($CertVal->"name")); \
        message=("A certificate on " . $Identity . " " . $State . ".\n\n" . [ $FormatInfo $Cert ]) });
      $LogPrint info $ScriptName ("The certificate '" . ($CertVal->"name") . "' " . $State . \
          ", it is invalid after " . ($CertVal->"invalid-after") . ".");
    }
  }
} on-error={ }
