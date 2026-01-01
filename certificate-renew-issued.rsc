#!rsc by RouterOS
# RouterOS script: certificate-renew-issued
# Copyright (c) 2019-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# renew locally issued certificates
# https://rsc.eworm.de/doc/certificate-renew-issued.md

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global CertIssuedExportPass;

  :global LogPrint;
  :global MkDir;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
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
        $LogPrint info $ScriptName ("Issued a new certificate for '" . $CertVal->"common-name" . \
          "', exported to 'cert-issued/" . $CertVal->"common-name" . ".p12'.");
      } else={
        $LogPrint warning $ScriptName ("Failed creating directory, not exporting certificate.");
      }
    } else={
      $LogPrint info $ScriptName ("Issued a new certificate for '" . $CertVal->"common-name" . "'.");
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
