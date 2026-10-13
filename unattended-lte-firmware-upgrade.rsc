#!rsc by RouterOS
# RouterOS script: unattended-lte-firmware-upgrade
# Copyright (c) 2018-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, scheduler
#
# schedule unattended lte firmware upgrade
# https://rsc.eworm.de/doc/unattended-lte-firmware-upgrade.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=unattended-lte-firmware-upgrade, schema=f231d0e80dd157d0022fa102e5293133b9d7d9cc5d18785151ff81e3434c0c7b
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"unattended-lte-firmware-upgrade.current") "The LTE firmware is up to date on interface {interface}.";
:set ($LanguageEnglish->"unattended-lte-firmware-upgrade.different") "LTE firmware versions still differ. Upgrade failed anyway?";
:set ($LanguageEnglish->"unattended-lte-firmware-upgrade.failed") "LTE firmware upgrade on '{interface}' failed: {error}";
:set ($LanguageEnglish->"unattended-lte-firmware-upgrade.finished") "LTE firmware upgrade on '{interface}' finished, waiting for reset.";
:set ($LanguageEnglish->"unattended-lte-firmware-upgrade.missing") "No LTE firmware information available for interface {interface}.";
:set ($LanguageEnglish->"unattended-lte-firmware-upgrade.query.failed") "Could not get latest LTE firmware version for interface {interface}: {error}";
:set ($LanguageEnglish->"unattended-lte-firmware-upgrade.scheduling") "Scheduling LTE firmware upgrade for interface {interface}.";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

# BEGIN GENERATED LOCAL LANGUAGE RENDERER
:local Translate do={
  :local Key [ :tostr $1 ];
  :local Params $2;
  :global ScriptLanguage;
  :global LanguageEnglish;
  :global LanguageMessages;
  :global LanguageActive;

  :local English ($LanguageEnglish->$Key);
  :if ([ :typeof $English ] != "str") do={ :return $Key; }
  :local Text $English;
  :if ($LanguageActive = $ScriptLanguage && [ :typeof ($LanguageMessages->$Key) ] = "str") do={
    :set Text ($LanguageMessages->$Key);
  }
  :local Tokens do={
    :local Text $1;
    :local Names ({});
    :while ([ :len $Text ] > 0) do={
      :local Start [ :find $Text "{" ];
      :if ([ :typeof $Start ] = "nil") do={
        :if ([ :typeof [ :find $Text "}" ] ] != "nil") do={ :return false; }
        :return $Names;
      }
      :local End [ :find $Text "}" $Start ];
      :if ([ :typeof $End ] = "nil") do={ :return false; }
      :if ([ :typeof [ :find [ :pick $Text 0 $Start ] "}" ] ] != "nil") do={ :return false; }
      :local Name [ :pick $Text ($Start + 1) $End ];
      :if (!($Name ~ "^[a-z][a-z0-9_]*\$")) do={ :return false; }
      :set ($Names->$Name) true;
      :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
    }
    :return $Names;
  }
  :local EnglishTokens [ $Tokens $English ];
  :local TranslatedTokens [ $Tokens $Text ];
  :local Valid false;
  :if ([ :typeof $TranslatedTokens ] = "array" && \
       [ :len $EnglishTokens ] = [ :len $TranslatedTokens ]) do={
    :set Valid true;
    :foreach Name,Unused in=$EnglishTokens do={
      :if (($TranslatedTokens->$Name) != true) do={ :set Valid false; }
    }
  }
  :if ($Valid != true) do={ :set Text $English; }
  :local Result "";
  :while ([ :len $Text ] > 0) do={
    :local Start [ :find $Text "{" ];
    :if ([ :typeof $Start ] = "nil") do={ :return ($Result . $Text); }
    :local End [ :find $Text "}" $Start ];
    :if ([ :typeof $End ] = "nil") do={ :return $English; }
    :local Name [ :pick $Text ($Start + 1) $End ];
    :if ([ :typeof ($Params->$Name) ] = "nothing" || \
         [ :typeof ($Params->$Name) ] = "nil") do={ :return $English; }
    :set Result ($Result . [ :pick $Text 0 $Start ] . [ :tostr ($Params->$Name) ]);
    :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
  }
  :return $Result;
}
# END GENERATED LOCAL LANGUAGE RENDERER

:foreach Interface in=[ /interface/lte/find where running ] do={
  :local Firmware;
  :local IntName [ /interface/lte/get $Interface name ];
  :onerror Err {
    :set Firmware [ /interface/lte/firmware-upgrade $Interface as-value ];
  } do={
    :log debug [ $Translate "unattended-lte-firmware-upgrade.query.failed" \
        ({ interface=$IntName; error=$Err }) ];
  }

  :if ([ :typeof $Firmware ] = "array") do={
    :if (($Firmware->"installed") != ($Firmware->"latest")) do={
      :log info [ $Translate "unattended-lte-firmware-upgrade.scheduling" \
          ({ interface=$IntName }) ];

      :global LTEFirmwareUpgrade do={
        # BEGIN GENERATED LOCAL LANGUAGE RENDERER
        :local Translate do={
          :local Key [ :tostr $1 ];
          :local Params $2;
          :global ScriptLanguage;
          :global LanguageEnglish;
          :global LanguageMessages;
          :global LanguageActive;

          :local English ($LanguageEnglish->$Key);
          :if ([ :typeof $English ] != "str") do={ :return $Key; }
          :local Text $English;
          :if ($LanguageActive = $ScriptLanguage && [ :typeof ($LanguageMessages->$Key) ] = "str") do={
            :set Text ($LanguageMessages->$Key);
          }
          :local Tokens do={
            :local Text $1;
            :local Names ({});
            :while ([ :len $Text ] > 0) do={
              :local Start [ :find $Text "{" ];
              :if ([ :typeof $Start ] = "nil") do={
                :if ([ :typeof [ :find $Text "}" ] ] != "nil") do={ :return false; }
                :return $Names;
              }
              :local End [ :find $Text "}" $Start ];
              :if ([ :typeof $End ] = "nil") do={ :return false; }
              :if ([ :typeof [ :find [ :pick $Text 0 $Start ] "}" ] ] != "nil") do={ :return false; }
              :local Name [ :pick $Text ($Start + 1) $End ];
              :if (!($Name ~ "^[a-z][a-z0-9_]*\$")) do={ :return false; }
              :set ($Names->$Name) true;
              :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
            }
            :return $Names;
          }
          :local EnglishTokens [ $Tokens $English ];
          :local TranslatedTokens [ $Tokens $Text ];
          :local Valid false;
          :if ([ :typeof $TranslatedTokens ] = "array" && \
               [ :len $EnglishTokens ] = [ :len $TranslatedTokens ]) do={
            :set Valid true;
            :foreach Name,Unused in=$EnglishTokens do={
              :if (($TranslatedTokens->$Name) != true) do={ :set Valid false; }
            }
          }
          :if ($Valid != true) do={ :set Text $English; }
          :local Result "";
          :while ([ :len $Text ] > 0) do={
            :local Start [ :find $Text "{" ];
            :if ([ :typeof $Start ] = "nil") do={ :return ($Result . $Text); }
            :local End [ :find $Text "}" $Start ];
            :if ([ :typeof $End ] = "nil") do={ :return $English; }
            :local Name [ :pick $Text ($Start + 1) $End ];
            :if ([ :typeof ($Params->$Name) ] = "nothing" || \
                 [ :typeof ($Params->$Name) ] = "nil") do={ :return $English; }
            :set Result ($Result . [ :pick $Text 0 $Start ] . [ :tostr ($Params->$Name) ]);
            :set Text [ :pick $Text ($End + 1) [ :len $Text ] ];
          }
          :return $Result;
        }
        # END GENERATED LOCAL LANGUAGE RENDERER

        :global LTEFirmwareUpgrade;
        :set LTEFirmwareUpgrade;

        /system/scheduler/remove ($1 . "-firmware-upgrade");
        :onerror Err {
          /interface/lte/firmware-upgrade $1 upgrade=yes;
          :log info [ $Translate "unattended-lte-firmware-upgrade.finished" \
              ({ interface=$1 }) ];
          :delay 240s;
          :local Firmware [ /interface/lte/firmware-upgrade $1 as-value ];
          :if ([ :len ($Firmware->"latest") ] > 0 && \
               ($Firmware->"installed") != ($Firmware->"latest")) do={
            :log warning [ $Translate "unattended-lte-firmware-upgrade.different" ];
          }
        } do={
          :log error [ $Translate "unattended-lte-firmware-upgrade.failed" \
              ({ interface=$1; error=$Err }) ];
        }
      }

      /system/scheduler/add name=($IntName . "-firmware-upgrade") start-time=startup interval=2s \
        on-event=(":global LTEFirmwareUpgrade; \$LTEFirmwareUpgrade \"" . $IntName . "\";");
    } else={
      :log info [ $Translate "unattended-lte-firmware-upgrade.current" \
          ({ interface=$IntName }) ];
    }
  } else={
    :log info [ $Translate "unattended-lte-firmware-upgrade.missing" \
        ({ interface=$IntName }) ];
  }
}
