#!rsc by RouterOS
# RouterOS script: dhcp-lease-comment.capsman
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: lease-script, order=60
# requires RouterOS, version=7.15
#
# update dhcp-server lease comment with infos from access-list
# https://rsc.eworm.de/doc/dhcp-lease-comment.md
#
# !! Do not edit this file, it is generated from template!

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
    :if ([ :len $AccessList ] > 0) do={
      :set NewComment [ /caps-man/access-list/get $AccessList comment ];
    }
    :if ([ :len $NewComment ] != 0 && $LeaseVal->"comment" != $NewComment) do={
      $LogPrint info $ScriptName ("Updating comment for DHCP lease " . $LeaseVal->"active-mac-address" . ": " . $NewComment);
      /ip/dhcp-server/lease/set comment=$NewComment $Lease;
    }
  }
} do={
  :global ExitError; $ExitError $ExitOK [ :jobname ] $Err;
}
