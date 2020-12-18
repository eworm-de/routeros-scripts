Initial commands
================

[◀ Go back to main README](README.md)

These command are inteneded for initial setup. If you are not aware of the
procedure please follow [the long way in detail](README.md#the-long-way-in-detail).

    {
      / tool fetch "https://git.eworm.de/cgit/routeros-scripts/plain/certs/R3.pem" dst-path="letsencrypt-R3.pem";
      :delay 1s;
      / certificate import file-name=letsencrypt-R3.pem passphrase="";
      :if ([ :len [ / certificate find where fingerprint="67add1166b020ae61b8f5fc96813c04c2aa589960796865572a3c7e737613dfd" or fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" or fingerprint="0687260331a72403d909f105e69bcf0d32e1bd2493ffc6d9206d11bcd6770739" ] ] != 3) do={
        :error "Something is wrong with your certificates!";
      }
      / file remove "letsencrypt-R3.pem";
      :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={
        / system script add name=$Script source=([ / tool fetch check-certificate=yes-without-crl ("https://git.eworm.de/cgit/routeros-scripts/plain/" . $Script) output=user as-value]->"data");
      }
      / system script set comment="ignore" global-config-overlay;
      / system script { run global-config; run global-config-overlay; run global-functions; }
      / system scheduler add name="global-scripts" start-time=startup on-event="/ system script { run global-config; run global-config-overlay; run global-functions; }";
      :global CertificateNameByCN;
      $CertificateNameByCN "R3";
      $CertificateNameByCN "ISRG Root X1";
      $CertificateNameByCN "DST Root CA X3";
    }

Optional to update the scripts automatically:

    / system scheduler add name="ScriptInstallUpdate" start-time=startup interval=1d on-event=":global ScriptInstallUpdate; \$ScriptInstallUpdate;";

---
[◀ Go back to main README](README.md)  
[▲ Go back to top](#top)
