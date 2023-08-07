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
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:local 0 "dhcp-lease-comment%TEMPL%";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global LogPrintExit2;
:global ScriptLock;

$ScriptLock $0;

:foreach Lease in=[ /ip/dhcp-server/lease/find where dynamic=yes status=bound ] do={
  :local LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
  :local NewComment;
  :local AccessList ([ /caps-man/access-list/find where mac-address=($LeaseVal->"active-mac-address") ]->0);
  :local AccessList ([ /interface/wireless/access-list/find where mac-address=($LeaseVal->"active-mac-address") ]->0);
  :if ([ :len $AccessList ] > 0) do={
    :set NewComment [ /caps-man/access-list/get $AccessList comment ];
    :set NewComment [ /interface/wireless/access-list/get $AccessList comment ];
  }
  :if ([ :len $NewComment ] != 0 && $LeaseVal->"comment" != $NewComment) do={
    $LogPrintExit2 info $0 ("Updating comment for DHCP lease " . $LeaseVal->"active-mac-address" . ": " . $NewComment) false;
    /ip/dhcp-server/lease/set comment=$NewComment $Lease;
  }
}
