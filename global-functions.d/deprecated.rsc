#!rsc by RouterOS
# RouterOS script: global-functions.d/deprecated
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.17
#
# deprecated global functions
# https://rsc.eworm.de/

:global ExitError;
:global HexToNum;

# wrapper for $ExitOnError with additional parameter
:set ExitError do={
  :local ExitOK [ :tostr $1 ];
  :local Name   [ :tostr $2 ];
  :local Error  [ :tostr $3 ];

  :global ExitOnError;

  :if ($ExitOK = "false") do={
    $ExitOnError $Name $Error;
  }
}

# convert from hex (string) to num
:set HexToNum do={
  :local Input [ :tostr $1 ];

  :global HexToNum;

  :if ([ :pick $Input 0 ] = "*") do={
    :return [ $HexToNum [ :pick  $Input 1 [ :len $Input ] ] ];
  }

  :return [ :tonum ("0x" . $Input) ];
}
