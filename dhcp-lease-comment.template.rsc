#!rsc by RouterOS
# RouterOS script: dhcp-lease-comment%TEMPL%
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: lease-script, order=60
# requires RouterOS, version=7.17
#
# update dhcp-server lease comment with infos from access-list
# https://rsc.eworm.de/doc/dhcp-lease-comment.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:local ExitOK false;
:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error ("Global config and/or functions not ready."); }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global LogPrint;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :set ExitOK true;
    :error false;
  }

  :foreach Lease in=[ /ip/dhcp-server/lease/find where dynamic=yes status=bound ] do={
    :local LeaseVal [ /ip/dhcp-server/lease/get $Lease ];
    :local NewComment;
    :local AccessList ([ /caps-man/access-list/find where mac-address=($LeaseVal->"active-mac-address") ]->0);
    :local AccessList ([ /interface/wifi/access-list/find where mac-address=($LeaseVal->"active-mac-address") ]->0);
    :local AccessList ([ /interface/wireless/access-list/find where mac-address=($LeaseVal->"active-mac-address") ]->0);
    :if ([ :len $AccessList ] > 0) do={
      :set NewComment [ /caps-man/access-list/get $AccessList comment ];
      :set NewComment [ /interface/wifi/access-list/get $AccessList comment ];
      :set NewComment [ /interface/wireless/access-list/get $AccessList comment ];
    }
    :if ([ :len $NewComment ] != 0 && $LeaseVal->"comment" != $NewComment) do={
      $LogPrint info $ScriptName ("Updating comment for DHCP lease " . $LeaseVal->"active-mac-address" . ": " . $NewComment);
      /ip/dhcp-server/lease/set comment=$NewComment $Lease;
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
