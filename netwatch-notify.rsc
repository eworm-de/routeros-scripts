#!rsc by RouterOS
# RouterOS script: netwatch-notify
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# monitor netwatch and send notifications
# https://rsc.eworm.de/doc/netwatch-notify.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=netwatch-notify, schema=7599eb0829fe6e5e2de9cf05b5bf721fd5b4cd7ce0726daf8735d47e695d7240
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"netwatch-notify.down.message") "The {type} '{name}' ({details}) is down since {since}.";
:set ($LanguageEnglish->"netwatch-notify.down.notified") "The {type} '{name}' ({details}) is down for {count} checks, already notified.";
:set ($LanguageEnglish->"netwatch-notify.down.parent") "The {type} '{name}' ({details}) is down for {count} checks, parent {type} {parent} is down.";
:set ($LanguageEnglish->"netwatch-notify.down.subject") "Netwatch Notify: {name} down";
:set ($LanguageEnglish->"netwatch-notify.down.waiting") "The {type} '{name}' ({details}) is down for {count} checks, {remaining} to go.";
:set ($LanguageEnglish->"netwatch-notify.hook.failed") "The {state}-hook for {type} '{name}' failed to run: {error}";
:set ($LanguageEnglish->"netwatch-notify.hook.failed.message") "The hook failed to run.";
:set ($LanguageEnglish->"netwatch-notify.hook.ran") "Ran hook on {type} '{name}' {state}: {hook}";
:set ($LanguageEnglish->"netwatch-notify.hook.ran.message") "Ran hook:\0A{hook}";
:set ($LanguageEnglish->"netwatch-notify.hook.syntax") "The {state}-hook for {type} '{name}' failed syntax validation.";
:set ($LanguageEnglish->"netwatch-notify.hook.syntax.message") "The hook failed syntax validation.";
:set ($LanguageEnglish->"netwatch-notify.note") "\0A\0ANote:\0A{note}";
:set ($LanguageEnglish->"netwatch-notify.resolve.failed") "Resolving name '{resolve}' failed third time: {error}";
:set ($LanguageEnglish->"netwatch-notify.resolve.named.failed") "Resolving name '{resolve}' for {type} '{name}' failed third time: {error}";
:set ($LanguageEnglish->"netwatch-notify.resolve.named.updated") "Name '{resolve}' for {type} '{name}' resolves to different address {address}, updating.";
:set ($LanguageEnglish->"netwatch-notify.resolve.updated") "Name '{resolve}' resolves to different address {address}, updating.";
:set ($LanguageEnglish->"netwatch-notify.state.down") "down";
:set ($LanguageEnglish->"netwatch-notify.state.pre-down") "pre-down";
:set ($LanguageEnglish->"netwatch-notify.state.up") "up";
:set ($LanguageEnglish->"netwatch-notify.type.host") "host";
:set ($LanguageEnglish->"netwatch-notify.type.service") "service";
:set ($LanguageEnglish->"netwatch-notify.up") "The {type} '{name}' ({details}) is up.";
:set ($LanguageEnglish->"netwatch-notify.up.message") "The {type} '{name}' ({details}) is up since {since}.\0AIt was down for {count} checks since {down_since}.";
:set ($LanguageEnglish->"netwatch-notify.up.subject") "Netwatch Notify: {name} up";
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

  :global NetwatchNotify;

  :global EitherOr;
  :global IfThenElse;
  :global IsDNSResolving;
  :global LogPrint;
  :global Translate;
  :global ParseKeyValueStore;
  :global ScriptFromTerminal;
  :global ScriptLock;
  :global SendNotification2;
  :global SymbolForNotification;

  :local NetwatchNotifyHook do={
    :local ScriptName [ :tostr $1 ];
    :local Name       [ :tostr $2 ];
    :local Type       [ :tostr $3 ];
    :local State      [ :tostr $4 ];
    :local Hook       [ :tostr $5 ];

    :global LogPrint;
    :global Translate;
    :global ValidateSyntax;

    :local TypeLabel [ $Translate "netwatch-notify.type.host" ];
    :if ($Type = "service") do={ :set TypeLabel [ $Translate "netwatch-notify.type.service" ]; };
    :local StateLabel [ $Translate "netwatch-notify.state.up" ];
    :if ($State = "down") do={ :set StateLabel [ $Translate "netwatch-notify.state.down" ]; };
    :if ($State = "pre-down") do={ :set StateLabel [ $Translate "netwatch-notify.state.pre-down" ]; };

    :if ([ $ValidateSyntax $Hook ] = true) do={
      onerror Err {
        [ :parse $Hook ];
      } do={
        $LogPrint warning $ScriptName [ $Translate "netwatch-notify.hook.failed" \
            ({ state=$StateLabel; type=$TypeLabel; name=$Name; error=$Err }) ];
        :return [ $Translate "netwatch-notify.hook.failed.message" ];
      }
    } else={
      $LogPrint warning $ScriptName [ $Translate "netwatch-notify.hook.syntax" \
          ({ state=$StateLabel; type=$TypeLabel; name=$Name }) ];
      :return [ $Translate "netwatch-notify.hook.syntax.message" ];
    }

    $LogPrint info $ScriptName [ $Translate "netwatch-notify.hook.ran" \
        ({ type=$TypeLabel; name=$Name; state=$StateLabel; hook=$Hook }) ];
    :return [ $Translate "netwatch-notify.hook.ran.message" \
        ({ hook=$Hook }) ];
  }

  :local ResolveExpected do={
    :local ScriptName [ :tostr $1 ];
    :local Name       [ :tostr $2 ];
    :local Expected   [ :tostr $3 ];

    :global GetRandom20CharAlNum;

    :local FwAddrList ($ScriptName . "-" . [ $GetRandom20CharAlNum ]);
    :if ([ :typeof [ :toip $Expected ] ] = "ip") do={
      /ip/firewall/address-list/add address=$Name list=$FwAddrList dynamic=yes timeout=30s;
      :delay 20ms;
      :if ([ :len [ /ip/firewall/address-list/find where list=$FwAddrList address=$Expected ] ] > 0) do={
        :return true;
      }
    }
    :if ([ :typeof [ :toip6 $Expected ] ] = "ip6") do={
      /ipv6/firewall/address-list/add address=$Name list=$FwAddrList dynamic=yes timeout=30s;
      :delay 20ms;
      :if ([ :len [ /ipv6/firewall/address-list/find where list=$FwAddrList address=$Expected ] ] > 0) do={
        :return true;
      }
    }

    :return false;
  }

  :if ([ $ScriptLock $ScriptName ] = false) do={
    :exit;
  }

  :local ScriptFromTerminalCached [ $ScriptFromTerminal $ScriptName ];

  :if ([ :typeof $NetwatchNotify ] = "nothing") do={
    :set NetwatchNotify ({});
  }

  :foreach Host in=[ /tool/netwatch/find where comment~"\\bnotify\\b" !disabled status!="unknown" ] do={
    :local HostVal [ /tool/netwatch/get $Host ];
    :local Type [ $IfThenElse ($HostVal->"type" ~ "^(https?-get|tcp-conn)\$") "service" "host" ];
    :local TypeLabel [ $Translate "netwatch-notify.type.host" ];
    :if ($Type = "service") do={ :set TypeLabel [ $Translate "netwatch-notify.type.service" ]; };
    :local HostInfo [ $ParseKeyValueStore ($HostVal->"comment") ];
    :local HostDetails ($HostVal->"host" . \
        [ $IfThenElse ([ :len ($HostInfo->"resolve") ] > 0) (", " . $HostInfo->"resolve") ]);

    :if ($HostInfo->"notify" = true && $HostInfo->"disabled" != true) do={
      :local Name [ $EitherOr ($HostInfo->"name") ($HostVal->"name") ];

      :local Metric { "count-down"=0; "count-up"=0; "notified"=false; "resolve-failcnt"=0 };
      :if ([ :typeof ($NetwatchNotify->$Name) ] = "array") do={
        :set $Metric ($NetwatchNotify->$Name);
      }

      :if ([ :typeof ($HostInfo->"resolve") ] = "str") do={
        :if ([ $IsDNSResolving ] = true) do={
          :onerror Err {
            :local Resolve [ :resolve type=[ $IfThenElse ([ :typeof ($HostVal->"host") ] = "ip") \
                "ipv4" "ipv6" ] ($HostInfo->"resolve") ];
            :if ($Resolve != $HostVal->"host") do={
              :if ([ $ResolveExpected $ScriptName ($HostInfo->"resolve") ($HostVal->"host") ] = false) do={
                :local Diagnostic [ $Translate "netwatch-notify.resolve.updated" \
                    ({ resolve=($HostInfo->"resolve"); address=$Resolve }) ];
                :if ($HostInfo->"resolve" != $HostInfo->"name") do={
                  :set Diagnostic [ $Translate "netwatch-notify.resolve.named.updated" \
                      ({ name=[ :tostr ($HostInfo->"name") ]; resolve=($HostInfo->"resolve"); type=$TypeLabel; address=$Resolve }) ];
                }
                $LogPrint info $ScriptName $Diagnostic;
                /tool/netwatch/set host=$Resolve $Host;
                :set ($Metric->"resolve-failcnt") 0;
                :set ($HostVal->"status") "unknown";
              }
            }
          } do={
            :set ($Metric->"resolve-failcnt") ($Metric->"resolve-failcnt" + 1);
            :if ($Metric->"resolve-failcnt" = 3) do={
              :local Diagnostic [ $Translate "netwatch-notify.resolve.failed" \
                  ({ resolve=($HostInfo->"resolve"); error=$Err }) ];
              :if ($HostInfo->"resolve" != $HostInfo->"name") do={
                :set Diagnostic [ $Translate "netwatch-notify.resolve.named.failed" \
                    ({ resolve=($HostInfo->"resolve"); name=[ :tostr ($HostInfo->"name") ]; type=$TypeLabel; error=$Err }) ];
              }
              $LogPrint [ $IfThenElse ($HostInfo->"no-resolve-fail" != true) warning debug ] $ScriptName $Diagnostic;
            }
          }
        }
      }

      :if ($HostVal->"status" = "up") do={
        :local CountDown ($Metric->"count-down");
        :if ($CountDown > 0) do={
          $LogPrint info $ScriptName \
              [ $Translate "netwatch-notify.up" \
                  ({ type=$TypeLabel; name=$Name; details=$HostDetails }) ];
          :set ($Metric->"count-down") 0;
        }
        :set ($Metric->"count-up") ($Metric->"count-up" + 1);
        :if ($Metric->"notified" = true) do={
          :local Message [ $Translate "netwatch-notify.up.message" \
              ({ type=$TypeLabel; name=$Name; details=$HostDetails; since=($HostVal->"since"); count=$CountDown; "down_since"=($Metric->"since") }) ];
          :if ([ :typeof ($HostInfo->"note") ] = "str") do={
            :set Message ($Message . [ $Translate "netwatch-notify.note" \
                ({ note=($HostInfo->"note") }) ]);
          }
          :if ([ :typeof ($HostInfo->"up-hook") ] = "str") do={
            :set Message ($Message . "\n\n" . [ $NetwatchNotifyHook $ScriptName $Name $Type "up" \
                ($HostInfo->"up-hook") ]);
          }
          $SendNotification2 ({ origin=[ $EitherOr ($HostInfo->"origin") $ScriptName ]; silent=($HostInfo->"silent"); \
            subject=([ $SymbolForNotification "white-heavy-check-mark" ] . [ $Translate "netwatch-notify.up.subject" \
                ({ name=$Name }) ]); \
            message=$Message; link=($HostInfo->"link") });
        }
        :set ($Metric->"notified") false;
        :set ($Metric->"parent") ($HostInfo->"parent");
        :set ($Metric->"since");
      }

      :if ($HostVal->"status" = "down") do={
        :set ($Metric->"count-down") ($Metric->"count-down" + 1);
        :set ($Metric->"count-up") 0;
        :set ($Metric->"parent") ($HostInfo->"parent");
        :set ($Metric->"since") ($HostVal->"since");
        :local CountDown [ $IfThenElse ([ :tonum ($HostInfo->"count") ] > 0) ($HostInfo->"count") 5 ];
        :local Parent ($HostInfo->"parent");
        :local ParentUp false;
        :while ([ :len $Parent ] > 0) do={
          :set CountDown ($CountDown + 1);
          :set Parent ($NetwatchNotify->$Parent->"parent");
        }
        :set Parent ($HostInfo->"parent");
        :local ParentNotified false;
        :while ($ParentNotified = false && [ :len $Parent ] > 0) do={
          :set ParentNotified [ $IfThenElse (($NetwatchNotify->$Parent->"notified") = true) \
              true false ];
          :set ParentUp ($NetwatchNotify->$Parent->"count-up");
          :if ($ParentNotified = false) do={
            :set Parent ($NetwatchNotify->$Parent->"parent");
          }
        }
        :if ($Metric->"notified" = false || $Metric->"count-down" % 120 = 0 || \
             $ScriptFromTerminalCached = true) do={
          :local Diagnostic [ $Translate "netwatch-notify.down.waiting" \
              ({ type=$TypeLabel; name=$Name; details=$HostDetails; count=($Metric->"count-down"); remaining=($CountDown - $Metric->"count-down") }) ];
          :if ($Metric->"notified" = true) do={ :set Diagnostic [ $Translate "netwatch-notify.down.notified" \
              ({ type=$TypeLabel; name=$Name; details=$HostDetails; count=($Metric->"count-down") }) ]; };
          :if ($ParentNotified = true) do={ :set Diagnostic [ $Translate "netwatch-notify.down.parent" \
              ({ type=$TypeLabel; name=$Name; details=$HostDetails; count=($Metric->"count-down"); parent=$Parent }) ]; };
          $LogPrint [ $IfThenElse ($HostInfo->"no-down-notification" != true) info debug ] $ScriptName $Diagnostic;
        }
        :if ((($CountDown * 2) - ($Metric->"count-down" * 3)) / 2 = 0 && \
             [ :typeof ($HostInfo->"pre-down-hook") ] = "str") do={
          $NetwatchNotifyHook $ScriptName $Name $Type "pre-down" ($HostInfo->"pre-down-hook");
        }
        :if ($ParentNotified = false && $Metric->"count-down" >= $CountDown && \
             ($ParentUp = false || $ParentUp > 2) && $Metric->"notified" != true) do={
          :local Message [ $Translate "netwatch-notify.down.message" \
              ({ type=$TypeLabel; name=$Name; details=$HostDetails; since=($HostVal->"since") }) ];
          :if ([ :typeof ($HostInfo->"note") ] = "str") do={
            :set Message ($Message . [ $Translate "netwatch-notify.note" \
                ({ note=($HostInfo->"note") }) ]);
          }
          :if ([ :typeof ($HostInfo->"down-hook") ] = "str") do={
            :set Message ($Message . "\n\n" . [ $NetwatchNotifyHook $ScriptName $Name $Type "down" \
                ($HostInfo->"down-hook") ]);
          }
          :if ($HostInfo->"no-down-notification" != true) do={
            $SendNotification2 ({ origin=[ $EitherOr ($HostInfo->"origin") $ScriptName ]; silent=($HostInfo->"silent"); \
              subject=([ $SymbolForNotification "cross-mark" ] . [ $Translate "netwatch-notify.down.subject" \
                  ({ name=$Name }) ]); \
              message=$Message; link=($HostInfo->"link") });
          }
          :set ($Metric->"notified") true;
        }
      }

      :set ($NetwatchNotify->$Name) {
        "count-down"=($Metric->"count-down");
        "count-up"=($Metric->"count-up");
        "notified"=($Metric->"notified");
        "parent"=($Metric->"parent");
        "resolve-failcnt"=($Metric->"resolve-failcnt");
        "since"=($Metric->"since") };
    }
  }
} do={
  :global ExitOnError; $ExitOnError [ :jobname ] $Err;
}
