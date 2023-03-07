#!rsc by RouterOS
# RouterOS script: dhcp-lease-comment%TEMPL%
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# provides: lease-script, order=60
#
# update dhcp-server lease comment with infos from access-list
# https://git.eworm.de/cgit/routeros-scripts/about/doc/dhcp-lease-comment.md
#
# !! This is just a template! Replace '%PATH%' with 'caps-man'
# !! or 'interface wireless'!

:local 0 "dhcp-lease-comment%TEMPL%";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global LogPrintExit2;

:foreach Lease in=[ /ip/dhcp-server/lease/find where dynamic=yes status=bound ] do={
  :local LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
  :local NewComment;
  :local AccessList ([ /%PATH%/access-list/find where mac-address=($LeaseVal->"mac-address") ]->0);
  :if ([ :len $AccessList ] > 0) do={
    :set NewComment [ /%PATH%/access-list/get $AccessList comment ];
  }
  :if ([ :len $NewComment ] != 0 && $LeaseVal->"comment" != $NewComment) do={
    $LogPrintExit2 info $0 ("Updating comment for DHCP lease " . $LeaseVal->"mac-address" . ": " . $NewComment) false;
    /ip/dhcp-server/lease/set comment=$NewComment $Lease;
  }
}
