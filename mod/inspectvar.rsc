#!rsc by RouterOS
# RouterOS script: mod/inspectvar
# Copyright (c) 2020-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# inspect variables
# https://git.eworm.de/cgit/routeros-scripts/about/doc/mod/inspectvar.md

:global InspectVar;
:global InspectVarReturn;

# inspect variable and print on terminal
:set InspectVar do={
  :global InspectVarReturn;
  :global PrettyPrint;

  $PrettyPrint [ $InspectVarReturn $1 ];
}

# inspect variable and return formatted string
:set InspectVarReturn do={
  :local Input $1;
  :local Level (0 + [ :tonum $2 ]);

  :global IfThenElse;
  :global InspectVarReturn;

  :local IndentReturn do={
    :local Prefix [ :tostr $1 ];
    :local Value  [ :tostr $2 ];
    :local Level  [ :tonum $3 ];

    :local Indent "";
    :for I from=1 to=$Level step=1 do={
      :set Indent ($Indent . "  ");
    }
    :return ($Indent . "-" . $Prefix . "-> " . $Value);
  }

  :local TypeOf [ :typeof $Input ];
  :local Return [ $IndentReturn "type" $TypeOf $Level ];

  :if ($TypeOf = "array") do={
    :foreach Key,Value in=$Input do={
      :set $Return ($Return . "\n" . \
        [ $IndentReturn "key" $Key ($Level + 1) ] . "\n" . \
        [ $InspectVarReturn $Value ($Level + 2) ]);
    }
  } else={
    :if ($TypeOf != "nothing") do={
      :set $Return ($Return . "\n" . \
        [ $IndentReturn "value" [ $IfThenElse ([ :len $Input ] > 80) \
        ([ :pick $Input 0 77 ] . "...") $Input ] $Level ]);
    }
  }
  :return $Return;
}
