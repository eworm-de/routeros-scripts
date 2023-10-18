#!rsc by RouterOS
# RouterOS script: check-lte-state-update
# Copyright (c) 2018-2022 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# check for LTE state, send notification
# https://git.eworm.de/cgit/routeros-scripts/about/doc/check-lte-state-update.md

:local 0 "check-lte-state-update";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global CurrentLteStatePrimaryBand

:if ([ :typeof $CurrentLteStatePrimaryBand ] != "array") do={
  :global CurrentLteStatePrimaryBand ({});
}

:global CurrentLteStateCaBand

:if ([ :typeof $CurrentLteStateCaBand ] != "array") do={
  :global CurrentLteStateCaBand ({});
}

:global CurrentLteStateIp

:if ([ :typeof $CurrentLteStateIp ] != "array") do={
  :global CurrentLteStateIp ({});
}

$LogPrintExit2 debug $0 ("Prepared") false;
 
:local CheckInterface do={
  :local Interface $1;

  :global Identity;
  :global SentLteStateUpdateNotification;
  :global CurrentLteStatePrimaryBand;
  :global CurrentLteStateCaBand;
  :global CurrentLteStateIp;
  :global CharacterReplace;
  :global LogPrintExit2;
  :global ScriptFromTerminal;
  :global SendNotification2;
  :global SymbolForNotification;
  :global CheckLteStateUpdateBtestHost;
  :global CheckLteStateUpdateBtestUser;
  :global CheckLteStateUpdateBtestPassword;
  :global CheckLteStateUpdateIp;
  :if ([ :typeof $CheckLteStateUpdateIp ] != "bool") do={
    :global CheckLteStateUpdateIp (true);
  }
  :global CheckLteStateUpdatePrimaryBand;
  :if ([ :typeof $CheckLteStateUpdatePrimaryBand ] != "bool") do={
    :global CheckLteStateUpdatePrimaryBand (false);
  }
  :global CheckLteStateUpdateCABand;
  :if ([ :typeof $CheckLteStateUpdateCABand ] != "bool") do={
    :global CheckLteStateUpdateCABand (false);
  }

  :local IntName [ /interface/lte/get $Interface name ];
  :local Ip [ /ip address get [ find interface=$IntName ] address ]
  :local Info;
  :do {
    :set Info [ /interface/lte/monitor $Interface once as-value ];
  } on-error={
    $LogPrintExit2 debug $0 ("Could not get latest LTE monitoring information for interface " . \
      $IntName . ".") false;
    :return false;
  }
  :local CurrentOperator ($Info->"current-operator");
  :local PrimaryBand ($Info->"primary-band");
  :local CaBand ($Info->"ca-band");
  :local Sinr ($Info->"sinr");
  :local Rssi ($Info->"rssi");
  :local Rsrq ($Info->"rsrq");
  :local Rsrp ($Info->"rsrp");
  :local Ri ($Info->"ri");
  :local PassedCheck false;
  :local CurrentPrimaryBand ($CurrentLteStatePrimaryBand->$IntName);
  :local CurrentCaBand ($CurrentLteStateCaBand->$IntName);
  :local CurrentIP ($CurrentLteStateIp->$IntName);

  :local IpMessage;
  :local PrimaryBandMessage;
  :local CaBandMessage

  :if ($CheckLteStateUpdateIp && $CurrentIP != $Ip) do={
    :set IpMessage ("IP address changed from $CurrentIP to $Ip\n");
    :set ($CurrentLteStateIp->$IntName) $Ip;
    :set PassedCheck (true);
  }
  :if ($CheckLteStateUpdatePrimaryBand && $CurrentPrimaryBand != $PrimaryBand) do={
    :set PrimaryBandMessage ("Primary band changed from $CurrentPrimaryBand to $PrimaryBand\n");
    :set ($CurrentLteStatePrimaryBand->$IntName) $PrimaryBand;
    :set PassedCheck (true);
  }
  :if ($CheckLteStateUpdateCABand && $CurrentCaBand != $CaBand) do={
    :set CaBandMessage ("CA band changed\n");
    :set ($CurrentLteStateCaBand->$IntName) $CaBand;
    :set PassedCheck (true);
  }

  :if ($PassedCheck = false) do={
    :if ([ $ScriptFromTerminal $0 ] = true) do={
      $LogPrintExit2 info $0 ("No state update for LTE interface " . $IntName . ".") false;
    }
    :return true;
  }

  :local BtestMessage;
  :if ($CheckLteStateUpdateBtestHost) do={
    $LogPrintExit2 debug $0 ("Checking the speed for interface " . \
        $IntName . ".") false;
    /tool speed-test test-duration=5 address=[:resolve $CheckLteStateUpdateBtestHost] user=$CheckLteStateUpdateBtestUser password=$CheckLteStateUpdateBtestPassword  do={
      :local DownloadSpeed;
      :local UploadSpeed;

      :set DownloadSpeed ($"tcp-download");
      :set UploadSpeed ($"tcp-upload");
      :set BtestMessage ("
  btest:
      $DownloadSpeed
      $UploadSpeed
  ");
    }
  }

  :local Message;
  :set $Message ("LTE interface $IntName on $Identity has the following comm values:
$IpMessage$PrimaryBandMessage$CaBandMessage
CurrentOperator: $CurrentOperator
PrimaryBand: $PrimaryBand
sinr: $Sinr
rssi: $Rssi
rsrq: $Rsrq
rsrp: $Rsrp
ri:  $Ri
$BtestMessage
");

  :if (($SentLteStateUpdateNotification->$IntName) = ($Message)) do={
    $LogPrintExit2 debug $0 ("Already sent the LTE state update notification for message " . \
      ($Message) . ".") false;
    :return false;
  }

  $LogPrintExit2 info $0 ("A new LTE state " . ($Message) . " for " . \
    "LTE interface " . $IntName . ".") false;
  $SendNotification2 ({ origin=$0; \
    subject=([ $SymbolForNotification "sparkles" ] . "LTE state update"); \
    message=($Message); silent=true });
  :set ($SentLteStateUpdateNotification->$IntName) ($Message);
}

:foreach Interface in=[ /interface/lte/find ] do={
  $CheckInterface $Interface;
}
