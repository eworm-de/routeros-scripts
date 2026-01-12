#!rsc by RouterOS
# RouterOS script: mod/ipcalc
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.17
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
  :global NetMask6;

  :local Address [ :pick $Input 0 [ :find $Input "/" ] ];
  :local Bits [ :tonum [ :pick $Input ([ :find $Input "/" ] + 1) [ :len $Input ] ] ];
  :local Mask;
  :local One;
  :if ([ :typeof [ :toip $Address ] ] = "ip") do={
    :set Address [ :toip $Address ];
    :set Mask [ $NetMask4 $Bits ];
    :set One 0.0.0.1;
  } else={
    :set Address [ :toip6 $Address ];
    :set Mask [ $NetMask6 $Bits ];
    :set One ::1;
  }

  :local Return ({
    "address"=$Address;
    "netmask"=$Mask;
    "networkaddress"=($Address & $Mask);
    "networkbits"=$Bits;
    "network"=(($Address & $Mask) . "/" . $Bits);
    "hostmin"=(($Address & $Mask) | $One);
    "hostmax"=(($Address | ~$Mask) ^ $One);
    "broadcast"=($Address | ~$Mask);
  });

  :return $Return;
}
