#!rsc by RouterOS
# RouterOS script: mod/ipcalc
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# ip address calculation
# https://rsc.eworm.de/doc/mod/ipcalc.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=ipcalc, schema=0b5dd00de254693d43a55e15ad5ad523a5ccce670aa66ac5465cd42290fd718b
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"ipcalc.address") "Address";
:set ($LanguageEnglish->"ipcalc.broadcast") "Broadcast";
:set ($LanguageEnglish->"ipcalc.hostmax") "HostMax";
:set ($LanguageEnglish->"ipcalc.hostmin") "HostMin";
:set ($LanguageEnglish->"ipcalc.netmask") "Netmask";
:set ($LanguageEnglish->"ipcalc.network") "Network";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:global IPCalc;
:global IPCalcReturn;

# print netmask, network, min host, max host and broadcast
:set IPCalc do={ :onerror Err {
  :local Input [ :tostr $1 ];

  :global FormatLine;
  :global Translate;
  :global IPCalcReturn;

  :local Values [ $IPCalcReturn $1 ];

  :put [ :tocrlf ( \
    [ $FormatLine [ $Translate "ipcalc.address" ] ($Values->"address") ] . "\n" . \
    [ $FormatLine [ $Translate "ipcalc.netmask" ] ($Values->"netmask") ] . "\n" . \
    [ $FormatLine [ $Translate "ipcalc.network" ] ($Values->"network") ] . "\n" . \
    [ $FormatLine [ $Translate "ipcalc.hostmin" ] ($Values->"hostmin") ] . "\n" . \
    [ $FormatLine [ $Translate "ipcalc.hostmax" ] ($Values->"hostmax") ] . "\n" . \
    [ $FormatLine [ $Translate "ipcalc.broadcast" ] ($Values->"broadcast") ]) ];
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
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
