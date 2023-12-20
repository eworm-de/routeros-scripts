#!rsc by RouterOS
# RouterOS script: capsman-download-packages%TEMPL%
# Copyright (c) 2018-2023 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# download and cleanup packages for CAP installation from CAPsMAN
# https://git.eworm.de/cgit/routeros-scripts/about/doc/capsman-download-packages.md
#
# !! This is just a template to generate the real script!
# !! Pattern '%TEMPL%' is replaced, paths are filtered.

:local 0 "capsman-download-packages%TEMPL%";
:global GlobalFunctionsReady;
:while ($GlobalFunctionsReady != true) do={ :delay 500ms; }

:global CleanFilePath;
:global DownloadPackage;
:global LogPrintExit2;
:global MkDir;
:global ScriptLock;
:global WaitFullyConnected;

$ScriptLock $0;
$WaitFullyConnected;

:local PackagePath [ $CleanFilePath [ /caps-man/manager/get package-path ] ];
:local PackagePath [ $CleanFilePath [ /interface/wifi/capsman/get package-path ] ];
:local PackagePath [ $CleanFilePath [ /interface/wifiwave2/capsman/get package-path ] ];
:local InstalledVersion [ /system/package/update/get installed-version ];
:local Updated false;

:if ([ :len $PackagePath ] = 0) do={
  $LogPrintExit2 warning $0 ("The CAPsMAN package path is not defined, can not download packages.") true;
}

:if ([ :len [ /file/find where name=$PackagePath type="directory" ] ] = 0) do={
  :if ([ $MkDir $PackagePath ] = false) do={
    $LogPrintExit2 warning $0 ("Creating directory at CAPsMAN package path (" . \
      $PackagePath . ") failed!") true;
  }
  $LogPrintExit2 info $0 ("Created directory at CAPsMAN package path (" . $PackagePath . \
    "). Please place your packages!") false;
}

:foreach Package in=[ /file/find where type=package \
      package-version!=$InstalledVersion name~("^" . $PackagePath) ] do={
  :local File [ /file/get $Package ];
  :if ($File->"package-architecture" = "mips") do={
    :set ($File->"package-architecture") "mipsbe";
  }
  :if ([ $DownloadPackage ($File->"package-name") $InstalledVersion \
       ($File->"package-architecture") $PackagePath ] = true) do={
    :set Updated true;
    /file/remove $Package;
  }
}

:if ([ :len [ /file/find where type=package name~("^" . $PackagePath) ] ] = 0) do={
  $LogPrintExit2 info $0 ("No packages available, downloading default set.") false;
# NOT /interface/wifi/ #
# NOT /interface/wifiwave2/ #
  :foreach Arch in={ "arm"; "mipsbe" } do={
    :foreach Package in={ "routeros"; "wireless" } do={
# NOT /interface/wifi/ #
# NOT /interface/wifiwave2/ #
# NOT /caps-man/ #
  :foreach Arch in={ "arm"; "arm64" } do={
# NOT /interface/wifi/ #
    :foreach Package in={ "routeros"; "wifiwave2" } do={
# NOT /interface/wifi/ #
# NOT /interface/wifiwave2/ #
    :foreach Package in={ "routeros"; "wifi-qcom"; "wifi-qcom-ac" } do={
# NOT /interface/wifiwave2/ #
# NOT /caps-man/ #
      :if ([ $DownloadPackage $Package $InstalledVersion $Arch $PackagePath ] = true) do={
        :set Updated true;
      }
    }
  }
}

:if ($Updated = true) do={
  :local Script ([ /system/script/find where source~"\n# provides: capsman-rolling-upgrade\n" ]->0);
  :if ([ :len $Script ] > 0) do={
    /system/script/run $Script;
  } else={
    /caps-man/remote-cap/upgrade [ find where version!=$InstalledVersion ];
    /interface/wifi/capsman/remote-cap/upgrade [ find where version!=$InstalledVersion ];
    /interface/wifiwave2/capsman/remote-cap/upgrade [ find where version!=$InstalledVersion ];
  }
}
