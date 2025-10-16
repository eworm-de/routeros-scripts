#!rsc by RouterOS
# RouterOS script: mod/ipcalc
# Copyright (c) 2020-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.15
#
# ip address calculation
# https://rsc.eworm.de/doc/mod/ipcalc.md

:global IPCalc;
:global IPCalcReturn;

# print netmask, network, min host, max host and broadcast
:set IPCalc do={ :onerror Err {
  :local Input [ :tostr $1 ];

  :global FormatLine;
  :global IPCalcReturn;

  :local Values [ $IPCalcReturn $1 ];

  :put [ :tocrlf ( \
    [ $FormatLine "Address" ($Values->"address") ] . "\n" . \
    [ $FormatLine "Netmask" ($Values->"netmask") ] . "\n" . \
    [ $FormatLine "Network" ($Values->"network") ] . "\n" . \
    [ $FormatLine "HostMin" ($Values->"hostmin") ] . "\n" . \
    [ $FormatLine "HostMax" ($Values->"hostmax") ] . "\n" . \
    [ $FormatLine "Broadcast" ($Values->"broadcast") ]) ];
} do={
  :global ExitError; $ExitError false $0 $Err;
} }

# calculate and return netmask, network, min host, max host and broadcast
:set IPCalcReturn do={
  :local Input [ :tostr $1 ];

  :global NetMask4;

  :local Address [ :toip [ :pick $Input 0 [ :find $Input "/" ] ] ];
  :local Bits [ :tonum [ :pick $Input ([ :find $Input "/" ] + 1) [ :len $Input ] ] ];
  :local Mask [ $NetMask4 $Bits ];

  :local Return {
    "address"=$Address;
    "netmask"=$Mask;
    "networkaddress"=($Address & $Mask);
    "networkbits"=$Bits;
    "network"=(($Address & $Mask) . "/" . $Bits);
    "hostmin"=(($Address & $Mask) | 0.0.0.1);
    "hostmax"=(($Address | ~$Mask) ^ 0.0.0.1);
    "broadcast"=($Address | ~$Mask);
  }

  :return $Return;
}
