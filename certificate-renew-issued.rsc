#!rsc by RouterOS
# RouterOS script: certificate-renew-issued
# Copyright (c) 2019-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.12
#
# renew locally issued certificates
# https://git.eworm.de/cgit/routeros-scripts/about/doc/certificate-renew-issued.md

:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:local Main do={
  :local ScriptName [ :tostr $1 ];

  :global CertIssuedExportPass;

  :global LogPrintExit2;
  :global MkDir;
  :global ScriptLock;

  $ScriptLock $ScriptName;

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
        $LogPrintExit2 info $ScriptName ("Issued a new certificate for \"" . $CertVal->"common-name" . \
          "\", exported to \"cert-issued/" . $CertVal->"common-name" . ".p12\".") false;
      } else={
        $LogPrintExit2 warning $ScriptName ("Failed creating directory, not exporting certificate.") false;
      }
    } else={
      $LogPrintExit2 info $ScriptName ("Issued a new certificate for \"" . $CertVal->"common-name" . "\".") false;
    }
  }
}

$Main [ :jobname ];
