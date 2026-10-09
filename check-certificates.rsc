#!rsc by RouterOS
# RouterOS script: check-certificates
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch
#
# check for certificate validity
# https://rsc.eworm.de/doc/check-certificates.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=check-certificates, schema=470ef2fd806d0e33ea04acd3af97465171413917bd9d674c28b1a80d68cf7953
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"check-certificates.chain.incomplete") " (possibly incomplete!)";
:set ($LanguageEnglish->"check-certificates.chain.missing") "The certificate chain is not available!";
:set ($LanguageEnglish->"check-certificates.chain.self") "self-signed";
:set ($LanguageEnglish->"check-certificates.decryption.failed") "Decryption failed for certificate file '{file}'.";
:set ($LanguageEnglish->"check-certificates.download.failed") "Failed fetching certificate by '{name}': {error}";
:set ($LanguageEnglish->"check-certificates.download.try") "Trying type '{type}' for '{name}' (file '{file}')...";
:set ($LanguageEnglish->"check-certificates.download.unavailable") "Could not download certificate file '{file}'.";
:set ($LanguageEnglish->"check-certificates.label.alternatives") "SubjectAltNames";
:set ($LanguageEnglish->"check-certificates.label.chain") "Issuer chain";
:set ($LanguageEnglish->"check-certificates.label.common") "CommonName";
:set ($LanguageEnglish->"check-certificates.label.days") "    days";
:set ($LanguageEnglish->"check-certificates.label.fingerprint") "Fingerprint";
:set ($LanguageEnglish->"check-certificates.label.from") "    from";
:set ($LanguageEnglish->"check-certificates.label.issuer") "Issuer";
:set ($LanguageEnglish->"check-certificates.label.key") "Subject Key Id";
:set ($LanguageEnglish->"check-certificates.label.left") "    time left";
:set ($LanguageEnglish->"check-certificates.label.name") "Name";
:set ($LanguageEnglish->"check-certificates.label.private") "Private key";
:set ($LanguageEnglish->"check-certificates.label.to") "    to";
:set ($LanguageEnglish->"check-certificates.label.validity") "Validity:\0A";
:set ($LanguageEnglish->"check-certificates.passphrase.try") "Trying {index}. passphrase... ";
:set ($LanguageEnglish->"check-certificates.renew.failed") "Could not renew certificate '{name}'.";
:set ($LanguageEnglish->"check-certificates.renew.key.missing") "Old certificate '{name}' has a private key, new certificate does not. Aborting renew.";
:set ($LanguageEnglish->"check-certificates.renew.log") "The certificate '{name}' has been renewed.";
:set ($LanguageEnglish->"check-certificates.renew.message") "A certificate on {identity} has been renewed.\0A\0A{details}";
:set ($LanguageEnglish->"check-certificates.renew.older") "Old certificate is newer than the new one. Aborting renew.";
:set ($LanguageEnglish->"check-certificates.renew.replaced") "Certificate '{name}' was not updated, but replaced.";
:set ($LanguageEnglish->"check-certificates.renew.subject") "Certificate renewed: {name}";
:set ($LanguageEnglish->"check-certificates.renew.try") "Attempting to renew certificate '{name}'.";
:set ($LanguageEnglish->"check-certificates.renew.updated") "Certificate '{name}' was updated in place.";
:set ($LanguageEnglish->"check-certificates.renew.url.missing") "No CertRenewUrl given.";
:set ($LanguageEnglish->"check-certificates.scep") "Certificate '{name}' is handled by SCEP, skipping.";
:set ($LanguageEnglish->"check-certificates.status.available") "available";
:set ($LanguageEnglish->"check-certificates.status.expired") "expired";
:set ($LanguageEnglish->"check-certificates.status.expiring") "is about to expire";
:set ($LanguageEnglish->"check-certificates.status.missing") "missing";
:set ($LanguageEnglish->"check-certificates.success") "Success!";
:set ($LanguageEnglish->"check-certificates.warning.log") "The certificate '{name}' {state}, it is invalid after {date}.";
:set ($LanguageEnglish->"check-certificates.warning.message") "A certificate on {identity} {state}.\0A\0A{details}";
:set ($LanguageEnglish->"check-certificates.warning.subject") "Certificate warning: {name}";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :global GlobalNotReadyMessage;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error $GlobalNotReadyMessage; }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global CertRenewTime;
  :global CertRenewUrl;
  :global CertWarnTime;
  :global Identity;

  :global CertificateAvailable;
  :global EscapeForRegEx;
  :global IfThenElse;
  :global Translate;
  :global LogPrint;
  :global LogPrintOnce;
  :global ParseKeyValueStore;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;
  :global WaitFullyConnected;

  :local CheckCertificatesDownloadImport do={
    :local ScriptName [ :tostr $1 ];
    :local CertName   [ :tostr $2 ];
    :local FetchName  [ :tostr $3 ];

    :global CertRenewUrl;
    :global CertRenewPass;

    :global CertificateNameByCN;
    :global EscapeForRegEx;
    :global FetchUserAgentStr;
    :global Translate;
    :global LogPrint;
    :global RmFile;
    :global WaitForFile;

    :foreach Type in={ "p12"; "pem" } do={
      :local CertFileName ([ :convert to=url $FetchName ] . "." . $Type);
      $LogPrint debug $ScriptName ([ $Translate "check-certificates.download.try" ({ type=$Type; name=$CertName; file=$CertFileName }) ]);

      :do {
        :onerror Err {
          /tool/fetch check-certificate=yes-without-crl \
              http-header-field=({ [ $FetchUserAgentStr $ScriptName ] }) \
              ($CertRenewUrl . $CertFileName) dst-path=$CertFileName as-value;
        } do={
          :if (!($Err ~ "[Ss]tatus 404")) do={
            $LogPrint warning $0 ([ $Translate "check-certificates.download.failed" ({ name=$FetchName; error=$Err }) ]);
          }
          :error false;
        }
        $WaitForFile $CertFileName;

        :local DecryptionFailed true;
        :foreach I,PassPhrase in=$CertRenewPass do={
          :do {
            $LogPrint debug $ScriptName ([ $Translate "check-certificates.passphrase.try" ({ index=$I }) ]);
            :local Result [ /certificate/import file-name=$CertFileName passphrase=$PassPhrase as-value ];
            :if ($Result->"decryption-failures" = 0) do={
              $LogPrint debug $ScriptName ([ $Translate "check-certificates.success" ]);
              :set DecryptionFailed false;
            }
          } on-error={ }
        }
        $RmFile $CertFileName;

        :if ($DecryptionFailed = true) do={
          $LogPrint warning $ScriptName ([ $Translate "check-certificates.decryption.failed" ({ file=$CertFileName }) ]);
        }

        :foreach CertInChain in=[ /certificate/find where common-name!=$CertName !private-key \
            name~("^" . [ $EscapeForRegEx $CertFileName ] . "_[0-9]+\$") \
            !(subject-alt-name~("(^|\\W)(DNS|IP):" . [ $EscapeForRegEx $CertName ] . "(\\W|\$)")) \
            !(common-name=[]) ] do={
          $CertificateNameByCN [ /certificate/get $CertInChain common-name ];
        }

        :return true;
      } on-error={
        $LogPrint debug $ScriptName ([ $Translate "check-certificates.download.unavailable" ({ file=$CertFileName }) ]);
      }
    }

    :return false;
  }

  :local FormatInfo do={
    :global Translate;
    :local Cert $1;

    :global FormatLine;
    :global FormatMultiLines;
    :global IfThenElse;

    :local FormatExpire do={
      :global CharacterReplace;
      :return [ $CharacterReplace [ $CharacterReplace [ :tostr $1 ] "w" "w " ] "d" "d " ];
    }

    :local FormatCertChain do={
      :global Translate;
      :local Cert $1;

      :global ParseKeyValueStore;

      :local CertVal [ /certificate/get $Cert ];

      :if ([ :typeof ($CertVal->"issuer") ] = "nothing") do={
        :return [ $Translate "check-certificates.chain.self" ];
      }

      :local Return "";
      :for I from=0 to=5 do={
        :set Return ($Return . [ $ParseKeyValueStore ($CertVal->"issuer") ]->"CN");
        :if ([ :len [ /certificate/builtin/find where skid=($CertVal->"akid") ] ] > 0) do={
          :return $Return;
        }
        :do {
          :set CertVal [ /certificate/get [ find where skid=($CertVal->"akid") ] ];
        } on-error={
          :return ($Return . [ $Translate "check-certificates.chain.incomplete" ]);
        }
        :if (($CertVal->"akid") = "" || ($CertVal->"akid") = ($CertVal->"skid")) do={
          :return $Return;
        }
        :set Return ($Return . " -> ");
      }
      :return ($Return . "...");
    }

    :local CertVal [ /certificate/get $Cert ];

    :return ( \
      [ $FormatLine [ $Translate "check-certificates.label.name" ] ($CertVal->"name") ] . "\n" . \
      [ $IfThenElse ([ :len ($CertVal->"common-name") ] > 0) ([ $FormatLine [ $Translate "check-certificates.label.common" ] ($CertVal->"common-name") ] . "\n") ] . \
      [ $IfThenElse ([ :len ($CertVal->"subject-alt-name") ] > 0) ([ $FormatMultiLines [ $Translate "check-certificates.label.alternatives" ] ($CertVal->"subject-alt-name") ] . "\n") ] . \
      [ $FormatLine [ $Translate "check-certificates.label.private" ] [ $IfThenElse (($CertVal->"private-key") = true) [ $Translate "check-certificates.status.available" ] [ $Translate "check-certificates.status.missing" ] ] ] . "\n" . \
      [ $FormatLine [ $Translate "check-certificates.label.fingerprint" ] ($CertVal->"fingerprint") ] . "\n" . \
      [ $FormatLine [ $Translate "check-certificates.label.key" ] ($CertVal->"skid") ] . "\n" . \
      [ $IfThenElse ([ :len ($CertVal->"ca") ] > 0) [ $FormatLine [ $Translate "check-certificates.label.issuer" ] ($CertVal->"ca") ] [ $FormatLine [ $Translate "check-certificates.label.chain" ] [ $FormatCertChain $Cert ] ] ] . "\n" . \
      [ $Translate "check-certificates.label.validity" ] . \
      [ $FormatLine [ $Translate "check-certificates.label.days" ] ($CertVal->"days-valid") ] . "\n" . \
      [ $FormatLine [ $Translate "check-certificates.label.from" ] ($CertVal->"invalid-before") ] . "\n" . \
      [ $FormatLine [ $Translate "check-certificates.label.to" ] ($CertVal->"invalid-after") ] . "\n" . \
      [ $FormatLine [ $Translate "check-certificates.label.left" ] [ $IfThenElse (($CertVal->"expired") = true) [ $Translate "check-certificates.status.expired" ] [ $FormatExpire ($CertVal->"expires-after") ] ] ]);
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }
  $WaitFullyConnected;

  :foreach Cert in=[ /certificate/find where !revoked !scep-url expires-after<$CertRenewTime \
                     !ca (common-name or subject-alt-name) ] do={
    :local CertVal [ /certificate/get $Cert ];
    :local LastName;
    :local FetchName;

    :do {
      :if ([ :len $CertRenewUrl ] = 0) do={
        $LogPrintOnce info $ScriptName ([ $Translate "check-certificates.renew.url.missing" ]);
        :break;
      }
      $LogPrint info $ScriptName ([ $Translate "check-certificates.renew.try" ({ name=($CertVal->"name") }) ]);

      :local ImportSuccess false;
      :if ([ :len ($CertVal->"common-name") ] > 0) do={
        :set LastName ($CertVal->"common-name");
        :set FetchName $LastName;
        :set ImportSuccess [ $CheckCertificatesDownloadImport $ScriptName $LastName $FetchName ];
      }
      :foreach SAN in=($CertVal->"subject-alt-name") do={
        :if ($ImportSuccess = false) do={
          :set LastName [ :pick $SAN ([ :find $SAN ":" ] + 1) [ :len $SAN ] ];
          :set FetchName $LastName;
          :set ImportSuccess [ $CheckCertificatesDownloadImport $ScriptName $LastName $FetchName ];
          :if ($ImportSuccess = false && [ :pick $LastName 0 2 ] = "*.") do={
            :set FetchName ("star." . [ :pick $LastName 2 [ :len $LastName ] ]);
            :set ImportSuccess [ $CheckCertificatesDownloadImport $ScriptName $LastName $FetchName ];
          }
        }
      }
      :if ($ImportSuccess = false) do={ :error false; }

      :if ([ :len ($CertVal->"fingerprint") ] > 0 && $CertVal->"fingerprint" != [ /certificate/get $Cert fingerprint ]) do={
        $LogPrint debug $ScriptName ([ $Translate "check-certificates.renew.updated" ({ name=($CertVal->"name") }) ]);
        :set CertVal [ /certificate/get $Cert ];
      } else={
        $LogPrint debug $ScriptName ([ $Translate "check-certificates.renew.replaced" ({ name=($CertVal->"name") }) ]);

        :local CertNew [ /certificate/find where name~("^" . [ $EscapeForRegEx [ :convert to=url $FetchName ] ] . "\\.(p12|pem)_[0-9]+\$") \
          (common-name=($CertVal->"common-name") or subject-alt-name~("(^|\\W)(DNS|IP):" . [ $EscapeForRegEx $LastName ] . "(\\W|\$)")) \
          fingerprint!=[ :tostr ($CertVal->"fingerprint") ] ];
        :local CertNewVal [ /certificate/get $CertNew ];

        :if (($CertVal->"expires-after") > ($CertNewVal->"expires-after")) do={
          /certificate/remove $CertNew;
          $LogPrint warning $ScriptName ([ $Translate "check-certificates.renew.older" ]);
          :error false;
        }

        :if (($CertVal->"private-key") = true && ($CertVal->"private-key") != ($CertNewVal->"private-key")) do={
          /certificate/remove $CertNew;
          $LogPrint warning $ScriptName ([ $Translate "check-certificates.renew.key.missing" ({ name=($CertVal->"name") }) ]);
          :error false;
        }

        :if ([ $CertificateAvailable ([ $ParseKeyValueStore ($CertNewVal->"issuer") ]->"CN") "fetch" ] = false) do={
          $LogPrint warning $ScriptName ([ $Translate "check-certificates.chain.missing" ]);
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
        subject=([ $SymbolForNotification "lock-with-ink-pen" ] . [ $Translate "check-certificates.renew.subject" ({ name=($CertVal->"name") }) ]); \
        message=([ $Translate "check-certificates.renew.message" ({ identity=$Identity; details=[ $FormatInfo $Cert ] }) ]) });
      $LogPrint info $ScriptName ([ $Translate "check-certificates.renew.log" ({ name=($CertVal->"name") }) ]);
    } on-error={
      $LogPrint debug $ScriptName ([ $Translate "check-certificates.renew.failed" ({ name=($CertVal->"name") }) ]);
    }
  }

  :foreach Cert in=[ /certificate/find where !revoked !scep-url expires-after<$CertWarnTime \
                     !(expires-after=[]) !(fingerprint=[]) ] do={
    :local CertVal [ /certificate/get $Cert ];

    :if ([ :len [ /certificate/scep-server/find where ca-cert=($CertVal->"ca") ] ] > 0) do={
      $LogPrint debug $ScriptName ([ $Translate "check-certificates.scep" ({ name=($CertVal->"name") }) ]);
    } else={
      :local State [ $IfThenElse (($CertVal->"expired") = true) [ $Translate "check-certificates.status.expired" ] [ $Translate "check-certificates.status.expiring" ] ];

      $SendNotification2 ({ origin=$ScriptName; \
        subject=([ $SymbolForNotification "lock-with-ink-pen,warning-sign" ] . [ $Translate "check-certificates.warning.subject" ({ name=($CertVal->"name") }) ]); \
        message=([ $Translate "check-certificates.warning.message" ({ identity=$Identity; state=$State; details=[ $FormatInfo $Cert ] }) ]) });
      $LogPrint info $ScriptName ([ $Translate "check-certificates.warning.log" ({ name=($CertVal->"name"); state=$State; date=($CertVal->"invalid-after") }) ]);
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
