#!rsc by RouterOS
# RouterOS script: certificate-renew-issued
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# renew locally issued certificates
# https://rsc.eworm.de/doc/certificate-renew-issued.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=certificate-renew-issued, schema=9048d1a3bcb148168f2785f02dea50e8de90c9f3170cedabe6b72d99bc61a2fd
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"certificate-renew-issued.directory.failed") "Failed creating directory, not exporting certificate.";
:set ($LanguageEnglish->"certificate-renew-issued.exported") "Issued a new certificate for '{name}', exported to 'cert-issued/{name}.p12'.";
:set ($LanguageEnglish->"certificate-renew-issued.issued") "Issued a new certificate for '{name}'.";
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global CertIssuedExportPass;

  :global LogPrint;
  :global Translate;
  :global MkDir;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :foreach Cert in=[ /certificate/find where issued expires-after<3w ] do={
    :local CertVal [ /certificate/get $Cert ];
    /certificate/issued-revoke $Cert;
    /certificate/set name=($CertVal->"name" . "-revoked-" . [ /system/clock/get date ]) $Cert;
    /certificate/add name=($CertVal->"name") common-name=($CertVal->"common-name") \
        key-usage=($CertVal->"key-usage") subject-alt-name=($CertVal->"subject-alt-name");
    /certificate/sign ($CertVal->"name") ca=($CertVal->"ca");
    :if ([ :typeof ($CertIssuedExportPass->($CertVal->"common-name")) ] = "str") do={
      :if ([ $MkDir "cert-issued" ] = true) do={
        /certificate/export-certificate ($CertVal->"name") type=pkcs12 \
            file-name=("cert-issued/" . $CertVal->"common-name") \
            export-passphrase=($CertIssuedExportPass->($CertVal->"common-name"));
        $LogPrint info $ScriptName [ $Translate "certificate-renew-issued.exported" \
            ({ name=($CertVal->"common-name") }) ];
      } else={
        $LogPrint warning $ScriptName [ $Translate "certificate-renew-issued.directory.failed" ];
      }
    } else={
      $LogPrint info $ScriptName [ $Translate "certificate-renew-issued.issued" \
          ({ name=($CertVal->"common-name") }) ];
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
