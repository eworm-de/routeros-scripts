Initial commands
================

[◀ Go back to main README](README.md)

> ⚠️ **Warning**: These commands are inteneded for initial setup. If you are
> not aware of the procedure please follow
> [the long way in detail](README.md#the-long-way-in-detail).

Run the complete base installation:

    {
      / tool fetch "https://git.eworm.de/cgit/routeros-scripts/plain/certs/ISRG-Root-X2.pem" dst-path="isrg-root-x2.pem" as-value;
      :delay 1s;
      / certificate import file-name=isrg-root-x2.pem passphrase="";
      :if ([ :len [ / certificate find where fingerprint="69729b8e15a86efc177a57afb7171dfc64add28c2fca8cf1507e34453ccb1470" ] ] != 1) do={
        :error "Something is wrong with your certificates!";
      };
      / file remove "isrg-root-x2.pem";
      :delay 1s;
      :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={
        / system script add name=$Script source=([ / tool fetch check-certificate=yes-without-crl ("https://git.eworm.de/cgit/routeros-scripts/plain/" . $Script . "\?h=routeros-v6") output=user as-value]->"data");
      };
      / system script { run global-config; run global-functions; };
      / system scheduler add name="global-scripts" start-time=startup on-event="/ system script { run global-config; run global-functions; }";
      :global CertificateNameByCN;
      $CertificateNameByCN "ISRG Root X2";
    }

Optional to update the scripts automatically:

    / system scheduler add name="ScriptInstallUpdate" start-time=startup interval=1d on-event=":global ScriptInstallUpdate; \$ScriptInstallUpdate;";

---
[◀ Go back to main README](README.md)  
[▲ Go back to top](#top)
