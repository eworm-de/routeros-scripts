#!rsc by RouterOS
# RouterOS script: mod/inspectvar
# Copyright (c) 2020-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# inspect variables
# https://rsc.eworm.de/doc/mod/inspectvar.md

:global InspectVar;
:global InspectVarReturn;

# inspect variable and print on terminal
:set InspectVar do={ :onerror Err {
  :global InspectVarReturn;

  :put [ :tocrlf [ $InspectVarReturn $1 ] ];
} do={
  :global ExitError; $ExitError false $0 $Err;
} }

# inspect variable and return formatted string
:set InspectVarReturn do={
  :local Input $1;
  :local Level (0 + [ :tonum $2 ]);

  :global CharacterReplace;
  :global IfThenElse;
  :global InspectVarReturn;

  :local IndentReturn do={
    :local Prefix [ :tostr $1 ];
    :local Value  [ :tostr $2 ];
    :local Level  [ :tonum $3 ];

    :global CharacterMultiply;

    :return ([ $CharacterMultiply " " $Level ] . "-" . $Prefix . "-> " . $Value);
  }

  :local TypeOf [ :typeof $Input ];
  :local Len    [ :len $Input ];
  :local Return [ $IndentReturn "type" $TypeOf $Level ];

  :if ($TypeOf = "array") do={
    :foreach Key,Value in=$Input do={
      :set $Return ($Return . "\n" . \
        [ $IndentReturn "key" $Key ($Level + 1) ] . "\n" . \
        [ $InspectVarReturn $Value ($Level + 2) ]);
    }
  } else={
    :if ($TypeOf = "str") do={
      :set $Return ($Return . "\n" . \
         [ $IndentReturn "len" $Len $Level ]);
      :if ([ :typeof [ :find $Input ("\r") ] ] = "num") do={
        :set Input [ $CharacterReplace $Input ("\r") "" ];
      }
      :if ([ :typeof [ :find $Input ("\n") ] ] = "num") do={
        :set Input [ $CharacterReplace $Input ("\n") " " ];
      }
    }
    :if ($TypeOf != "nothing") do={
      :set $Return ($Return . "\n" . \
        [ $IndentReturn "value" [ $IfThenElse ([ :len $Input ] > 80) \
        ([ :pick $Input 0 77 ] . "...") $Input ] $Level ]);
    }
  }
  :return $Return;
}
