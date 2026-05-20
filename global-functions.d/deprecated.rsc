#!rsc by RouterOS
# RouterOS script: global-functions.d/deprecated
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.21
#
# deprecated global functions
# https://rsc.eworm.de/

:global HexToNum;
:global UrlEncode;

# convert from hex (string) to num
:set HexToNum do={
  :local Input [ :tostr $1 ];

  :global HexToNum;

  :if ([ :pick $Input 0 ] = "*") do={
    :return [ $HexToNum [ :pick  $Input 1 [ :len $Input ] ] ];
  }

  :return [ :tonum ("0x" . $Input) ];
}

# url encoding
:set UrlEncode do={
  :local Input [ :tostr $1 ];

  :if ([ :len $Input ] = 0) do={
    :return "";
  }

  :local Return "";
  :local Chars ("\n\r !\"#\$%&'()*+,:;<=>?@[\\]^`{|}~");
  :local Subs { "%0A"; "%0D"; "%20"; "%21"; "%22"; "%23"; "%24"; "%25"; "%26"; "%27";
         "%28"; "%29"; "%2A"; "%2B"; "%2C"; "%3A"; "%3B"; "%3C"; "%3D"; "%3E"; "%3F";
         "%40"; "%5B"; "%5C"; "%5D"; "%5E"; "%60"; "%7B"; "%7C"; "%7D"; "%7E" };

  :for I from=0 to=([ :len $Input ] - 1) do={
    :local Char [ :pick $Input $I ];
    :local Replace [ :find $Chars $Char ];

    :if ([ :typeof $Replace ] = "num") do={
      :set Char ($Subs->$Replace);
    }
    :set Return ($Return . $Char);
  }

  :return $Return;
}
