#!rsc by RouterOS
# RouterOS script: check-routeros-update
# Copyright (c) 2013-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# check for RouterOS update, send notification and/or install
# https://git.eworm.de/cgit/routeros-scripts/about/doc/check-routeros-update.md

:local 0 "check-routeros-update";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global Identity;
:global SafeUpdateAll;
:global SafeUpdateNeighbor;
:global SafeUpdatePatch;
:global SafeUpdateUrl;
:global SentRouterosUpdateNotification;

:global DeviceInfo;
:global LogPrintExit2;
:global ScriptFromTerminal;
:global ScriptLock;
:global SendNotification2;
:global SymbolForNotification;
:global VersionToNum;
:global WaitFullyConnected;

:local DoUpdate do={
  :if ([ :len [ /system/script/find where name="packages-update" ] ] > 0) do={
    /system/script/run packages-update;
  } else={
    /system/package/update/install without-paging;
  }
  :error "Waiting for system to reboot.";
}

$ScriptLock $0;

$WaitFullyConnected;

:if ([ :len [ /system/scheduler/find where name="\$RebootForUpdate" ] ] > 0) do={
  :error "A reboot for update is already scheduled.";
}

$LogPrintExit2 debug $0 ("Checking for updates...") false;
/system/package/update/check-for-updates without-paging as-value;
:local Update [ /system/package/update/get ];

:if ([ $ScriptFromTerminal $0 ] = true && ($Update->"installed-version") = ($Update->"latest-version")) do={
  $LogPrintExit2 info $0 ("System is already up to date.") true;
}

:local NumInstalled [ $VersionToNum ($Update->"installed-version") ];
:local NumLatest [ $VersionToNum ($Update->"latest-version") ];
:local Link ("https://mikrotik.com/download/changelogs/" . $Update->"channel" . "-release-tree");

:if ($NumLatest < 117505792) do={
  $LogPrintExit2 info $0 ("The version '" . ($Update->"latest-version") . "' is not a valid version.") true;
}

:if ($NumInstalled < $NumLatest) do={
  :if ($SafeUpdateAll ~ "^YES,? ?PLEASE!?\$") do={
    $LogPrintExit2 info $0 ("Installing ALL versions automatically, including " . \
      $Update->"latest-version" . "...") false;
    $SendNotification2 ({ origin=$0; \
      subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
      message=("Installing ALL versions automatically, including " . $Update->"latest-version" . \
        "... Updating on " . $Identity . "..."); link=$Link; silent=true });
    $DoUpdate;
  }

  :if ($SafeUpdatePatch = true && ($NumInstalled & 0xffff0000) = ($NumLatest & 0xffff0000)) do={
    $LogPrintExit2 info $0 ("Version " . $Update->"latest-version" . " is a patch release, updating...") false;
    $SendNotification2 ({ origin=$0; \
      subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
      message=("Version " . $Update->"latest-version" . " is a patch update for " . $Update->"channel" . \
        ", updating on " . $Identity . "..."); link=$Link; silent=true });
    $DoUpdate;
  }

  :if ($SafeUpdateNeighbor = true && [ :len [ /ip/neighbor/find where \
       version~($Update->"latest-version" . " \\(" . $Update->"channel" . "\\).*") ] ] > 0) do={
    $LogPrintExit2 info $0 ("Seen a neighbor running version " . $Update->"latest-version" . ", updating...") false;
    $SendNotification2 ({ origin=$0; \
      subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
      message=("Seen a neighbor running version " . $Update->"latest-version" . " from " . $Update->"channel" . \
        ", updating on " . $Identity . "..."); link=$Link; silent=true });
    $DoUpdate;
  }

  :if ([ :len $SafeUpdateUrl ] > 0) do={
    :local Result;
    :do {
      :set Result [ /tool/fetch check-certificate=yes-without-crl \
          ($SafeUpdateUrl . $Update->"channel" . "?installed=" . $Update->"installed-version" . \
          "&latest=" . $Update->"latest-version") output=user as-value ];
    } on-error={
      $LogPrintExit2 warning $0 ("Failed receiving safe version for " . $Update->"channel" . ".") false;
    }
    :if ($Result->"status" = "finished" && $Result->"data" = $Update->"latest-version") do={
      $LogPrintExit2 info $0 ("Version " . $Update->"latest-version" . " is considered safe, updating...") false;
      $SendNotification2 ({ origin=$0; \
        subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
        message=("Version " . $Update->"latest-version" . " is considered safe for " . $Update->"channel" . \
          ", updating on " . $Identity . "..."); link=$Link; silent=true });
      $DoUpdate;
    }
  }

  :if ([ $ScriptFromTerminal $0 ] = true) do={
    :put ("Do you want to install RouterOS version " . $Update->"latest-version" . "? [y/N]");
    :if (([ /terminal/inkey timeout=60 ] % 32) = 25) do={
      $DoUpdate;
    } else={
      :put "Canceled...";
    }
  }

  :if ($SentRouterosUpdateNotification = $Update->"latest-version") do={
    $LogPrintExit2 info $0 ("Already sent the RouterOS update notification for version " . \
        $Update->"latest-version" . ".") true;
  }

  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "sparkles" ] . "RouterOS update: " . $Update->"latest-version"); \
    message=("A new RouterOS version " . ($Update->"latest-version") . \
      " is available for " . $Identity . ".\n\n" . \
      [ $DeviceInfo ]); link=$Link; silent=true });
  :set SentRouterosUpdateNotification ($Update->"latest-version");
}

:if ($NumInstalled > $NumLatest) do={
  :if ($SentRouterosUpdateNotification = $Update->"latest-version") do={
    $LogPrintExit2 info $0 ("Already sent the RouterOS downgrade notification for version " . \
        $Update->"latest-version" . ".") true;
  }

  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "warning-sign" ] . "RouterOS version: " . $Update->"latest-version"); \
    message=("A different RouterOS version " . ($Update->"latest-version") . \
      " is available for " . $Identity . ", but it is a downgrade.\n\n" . \
      [ $DeviceInfo ]); link=$Link; silent=true });
  $LogPrintExit2 info $0 ("A different RouterOS version " . ($Update->"latest-version") . \
    " is available for downgrade.") false;
  :set SentRouterosUpdateNotification ($Update->"latest-version");
}
