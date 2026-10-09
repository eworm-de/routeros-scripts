#!rsc by RouterOS
# RouterOS script: mod/inspectvar
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# inspect variables
# https://rsc.eworm.de/doc/mod/inspectvar.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=inspectvar, schema=2cbc53e8cc3687bd7d014271c8fdb7251bcf5b16476385468b3e5d11dc9dd5c4
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"inspectvar.key") "key";
:set ($LanguageEnglish->"inspectvar.len") "len";
:set ($LanguageEnglish->"inspectvar.type") "type";
:set ($LanguageEnglish->"inspectvar.value") "value";
# END GENERATED LANGUAGE DATA

:global InspectVar;
:global InspectVarReturn;

# inspect variable and print on terminal
:set InspectVar do={ :onerror Err {
  :global InspectVarReturn;

  :put [ :tocrlf [ $InspectVarReturn $1 ] ];
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# inspect variable and return formatted string
:set InspectVarReturn do={
  :local Input $1;
  :local Level (0 + [ :tonum $2 ]);

  :global CharacterReplace;
  :global Translate;
  :global IfThenElse;
  :global InspectVarReturn;

  :local IndentReturn do={
    :local Prefix [ :tostr $1 ];
    :local Value  [ :tostr $2 ];
    :local Level  [ :tonum $3 ];

    :global CharacterMultiply;

    :return ([ $CharacterMultiply " " ($Level * 2) ] . "-" . $Prefix . "-> " . $Value);
  }

  :local TypeOf [ :typeof $Input ];
  :local Len    [ :len $Input ];
  :local Return [ $IndentReturn [ $Translate "inspectvar.type" ] $TypeOf $Level ];

  :if ($TypeOf = "array") do={
    :foreach Key,Value in=$Input do={
      :set $Return ($Return . "\n" . \
        [ $IndentReturn [ $Translate "inspectvar.key" ] $Key ($Level + 1) ] . "\n" . \
        [ $InspectVarReturn $Value ($Level + 2) ]);
    }
  } else={
    :if ($TypeOf = "str") do={
      :set $Return ($Return . "\n" . \
         [ $IndentReturn [ $Translate "inspectvar.len" ] $Len $Level ]);
      :if ([ :typeof [ :find $Input ("\r") ] ] = "num") do={
        :set Input [ $CharacterReplace $Input ("\r") "" ];
      }
      :if ([ :typeof [ :find $Input ("\n") ] ] = "num") do={
        :set Input [ $CharacterReplace $Input ("\n") " " ];
      }
    }
    :if ($TypeOf != "nothing") do={
      :set $Return ($Return . "\n" . \
        [ $IndentReturn [ $Translate "inspectvar.value" ] [ $IfThenElse ([ :len $Input ] > 80) \
        ([ :pick $Input 0 77 ] . "...") $Input ] $Level ]);
    }
  }
  :return $Return;
}
