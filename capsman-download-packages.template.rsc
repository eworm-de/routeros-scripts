#!rsc by RouterOS
# RouterOS script: capsman-download-packages%TEMPL%
# Copyright (c) 2018-2023 Christian Hesse <mail@eworm.de>
#                         Michael Gisbers <michael@gisbers.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# download and cleanup packages for CAP installation from CAPsMAN
# https://git.eworm.de/cgit/routeros-scripts/about/doc/capsman-download-packages.md
#
# !! This is just a template! Replace '%PATH%' with 'caps-man',
# !! 'interface/wireless' or 'interface/wifiwave2'!

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

:if ([ :len [ /system/logging/find where topics~"error" !(topics~"!error") \
     !(topics~"!caps") action=memory !disabled !invalid ] ] < 1) do={
  $LogPrintExit2 warning $0 ("Looks like error messages for 'caps' are not sent to memory. " . \
      "Probably can not download packages automatically.") false;
} else={
  :if ($Updated = false && [ /system/resource/get uptime ] < 2m) do={
    $LogPrintExit2 info $0 ("No packages downloaded, yet. Delaying for logs.") false;
    :delay 2m;
  }
}

:foreach Log in=[ /log/find where topics=({"caps"; "error"}) \
    message~("upgrade status: failed, failed to download file '.*-" . $InstalledVersion . \
    "-.*\\.npk', no such file") ] do={
  :local Message [ /log/get $Log message ];
  :local Package [ :pick $Message \
    ([ :find $Message "'" ] + 1) \
    [ :find $Message ("-" . $InstalledVersion . "-") ] ];
  :local Arch [ :pick $Message \
    ([ :find $Message ("-" . $InstalledVersion . "-") ] + 2 + [ :len $InstalledVersion ]) \
    [ :find $Message ".npk" ] ];
  :if ([ $DownloadPackage $Package $InstalledVersion $Arch $PackagePath ] = true) do={
    :set Updated true;
  }
}

:if ($Updated = true) do={
  :local Script ([ /system/script/find where source~"\n# provides: capsman-rolling-upgrade\n" ]->0);
  :if ([ :len $Script ] > 0) do={
    /system/script/run $Script;
  } else={
    /caps-man/remote-cap/upgrade [ find where version!=$InstalledVersion ];
    /interface/wifiwave2/capsman/remote-cap/upgrade [ find where version!=$InstalledVersion ];
  }
}
