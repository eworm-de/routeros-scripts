#!rsc by RouterOS
# RouterOS script: dhcp-lease-comment%TEMPL%
# Copyright (c) 2013-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# provides: dhcpv4-server-lease, order=60
# requires RouterOS, version=7.22
#
# update dhcp-server lease comment with infos from access-list
# https://rsc.eworm.de/doc/dhcp-lease-comment.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

# BEGIN GENERATED LANGUAGE DATA
# language, name=dhcp-lease-comment, schema=ad1da8da95495f80f8319fac06ad159a82bd84a7d3d038d72df426a6a87b98ef
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"dhcp-lease-comment.updating") "Updating comment for DHCP lease {mac}: {comment}";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:onerror Err {
  :global GlobalConfigReady; :global GlobalFunctionsReady;
  :global GlobalNotReadyMessage;
  :retry { :if ($GlobalConfigReady != true || $GlobalFunctionsReady != true) \
      do={ :error $GlobalNotReadyMessage; }; } delay=500ms max=50;
  :local ScriptName [ :jobname ];

  :global LogPrint;
  :global Translate;
  :global ScriptLock;

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
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
      $LogPrint info $ScriptName [ $Translate "dhcp-lease-comment.updating" \
          ({ mac=($LeaseVal->"active-mac-address"); comment=$NewComment }) ];
      /ip/dhcp-server/lease/set comment=$NewComment $Lease;
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
