Initial commands
================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](README.md)

> ⚠️ **Warning**: These command are inteneded for initial setup. If you are
> not aware of the procedure please follow
> [the long way in detail](README.md#the-long-way-in-detail).

Run the complete base installation:

    {
      :local localScriptUpdatesBaseUrl "https://git.eworm.de/cgit/routeros-scripts/plain/";
      :local localBaseUrlCert "ISRG-Root-X2.pem";
      :local localCertName "ISRG Root X2";
      :local localCertFilename "isrg-root-x2.pem";
      :local localCertFingerprint "69729b8e15a86efc177a57afb7171dfc64add28c2fca8cf1507e34453ccb1470";
      /tool/fetch ( $localScriptUpdatesBaseUrl . "certs/" . $localBaseUrlCert ) dst-path=$localCertFilename as-value;
      :delay 1s;
      /certificate/import file-name=$localCertFilename passphrase="";
      :if ([ :len [ /certificate/find where fingerprint=$localCertFingerprint ] ] != 1) do={
        :error "Something is wrong with your certificates!";
      } else={
        :put "Certificate validated with fingerprint";
      };
      :delay 1s;
      :put "Backup global-config-overlay...";
      /system/script/set name=("global-config-overlay-" . [ /system/clock/get date ] . "-" . [ /system/clock/get time ]) [ find where name="global-config-overlay" ];
      :foreach Script in={ "global-config"; "global-config-overlay"; "global-functions" } do={
        :put "Install $Script ...";
        /system/script/remove [ find where name=$Script ];
        /system/script/add name=$Script owner=$Script source=([ /tool/fetch check-certificate=yes-without-crl ($localScriptUpdatesBaseUrl . $Script . ".rsc") output=user as-value]->"data");
      };
      :put "Run new scripts ...";
      /system/script { run global-config; run global-functions; };
      /system/scheduler/remove [ find where name="global-scripts" ];
      :put "Schedule run scripts on startup";
      /system/scheduler/add name="global-scripts" start-time=startup on-event="/system/script { run global-config; run global-functions; }";
      :put "Rename certificate by its common-name ..."
      :global CertificateNameByCN;
      $CertificateNameByCN $localCertName;
    };

Then continue setup with
[scheduled automatic updates](README.md#scheduled-automatic-updates) or
[editing configuration](README.md#editing-configuration).

## Fix existing installation

The [initial commands](#initial-commands) above allow to fix an existing
installation in case it ever breaks. If `global-config-overlay` did exist
before it is renamed with a date and time suffix (like
`global-config-overlay-2024-01-25-09:33:12`). Make sure to restore the
configuration overlay if required.

---
[⬅️ Go back to main README](README.md)  
[⬆️ Go back to top](#top)
