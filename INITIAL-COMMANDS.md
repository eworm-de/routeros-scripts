Initial commands
================

[◀ Go back to main README](README.md)

These command are inteneded for initial setup. If you are not aware of the
procedure please follow [the long way in detail](README.md#the-long-way-in-detail).

One extra step is required if you run RouterOS v6:

    :global ScriptUpdatesUrlSuffix "\?h=routeros-v6";

Then run the complete base installation:

    {
      :global ScriptUpdatesUrlSuffix;
      / tool fetch "https://git.eworm.de/cgit/routeros-scripts/plain/certs/R3.pem" dst-path="letsencrypt-R3.pem" as-value;
      :delay 1s;
      / certificate import file-name=letsencrypt-R3.pem passphrase="";
      :if ([ :len [ / certificate find where fingerprint="67add1166b020ae61b8f5fc96813c04c2aa589960796865572a3c7e737613dfd" or fingerprint="96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6" ] ] != 2) do={
        :error "Something is wrong with your certificates!";
      };
      / file remove "letsencrypt-R3.pem";
      :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={
        / system script add name=$Script source=([ / tool fetch check-certificate=yes-without-crl ("https://git.eworm.de/cgit/routeros-scripts/plain/" . $Script . $ScriptUpdatesUrlSuffix) output=user as-value]->"data");
      };
      / system script { run global-config; run global-functions; };
      / system scheduler add name="global-scripts" start-time=startup on-event="/ system script { run global-config; run global-functions; }";
      :global CertificateNameByCN;
      $CertificateNameByCN "R3";
      $CertificateNameByCN "ISRG Root X1";
    }

Optional to update the scripts automatically:

    / system scheduler add name="ScriptInstallUpdate" start-time=startup interval=1d on-event=":global ScriptInstallUpdate; \$ScriptInstallUpdate;";

---
[◀ Go back to main README](README.md)  
[▲ Go back to top](#top)
