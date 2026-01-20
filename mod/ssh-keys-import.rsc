#!rsc by RouterOS
# RouterOS script: mod/ssh-keys-import
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.17
#
# import ssh keys for public key authentication
# https://rsc.eworm.de/doc/mod/ssh-keys-import.md

:global SSHKeysImport;
:global SSHKeysImportFile;

# import single key passed as string
:set SSHKeysImport do={ :onerror Err {
  :local Key  [ :tostr $1 ];
  :local User [ :tostr $2 ];

  :global GetRandom20CharAlNum;
  :global LogPrint;
  :global MkDir;
  :global RmDir;
  :global WaitForFile;

  :if ([ :len $Key ] = 0 || [ :len $User ] = 0) do={
    $LogPrint warning $0 ("Missing argument(s), please pass key and user!");
    :return false;
  }

  :if ([ :len [ /user/find where name=$User ] ] = 0) do={
    $LogPrint warning $0 ("User '" . $User . "' does not exist.");
    :return false;
  }

  :local KeyVal ([ :deserialize $Key delimiter=" " from=dsv options=dsv.plain ]->0);
  :if (!($KeyVal->0 = "ssh-ed25519" || $KeyVal->0 = "ssh-rsa")) do={
    $LogPrint warning $0 ("SSH key of type '" . $KeyVal->0 . "' is not supported.");
    :return false;
  }

  :local FingerPrintMD5 [ :convert from=base64 transform=md5 to=hex ($KeyVal->1) ];

  :local RegEx ("\\bmd5=" . $FingerPrintMD5 . "\\b");
  :if ([ :len [ /user/ssh-keys/find where user=$User \
       (key-owner~$RegEx or info~$RegEx) ] ] > 0) do={
    $LogPrint warning $0 ("The ssh public key (MD5:" . $FingerPrintMD5 . \
      ") is already available for user '" . $User . "'.");
    :return false;
  }

  :if ([ $MkDir "tmpfs/ssh-keys-import" ] = false) do={
    $LogPrint warning $0 ("Creating directory 'tmpfs/ssh-keys-import' failed!");
    :return false;
  }

  :local FileName ("tmpfs/ssh-keys-import/key-" . [ $GetRandom20CharAlNum 6 ] . ".pub");
  /file/add name=$FileName contents=($Key . ", md5=" . $FingerPrintMD5);
  $WaitForFile $FileName;

  :onerror Err {
    /user/ssh-keys/import public-key-file=$FileName user=$User;
    $LogPrint info $0 ("Imported ssh public key (" . $KeyVal->2 . ", " . $KeyVal->0 . ", " . \
      "MD5:" . $FingerPrintMD5 . ") for user '" . $User . "'.");
    $RmDir "tmpfs/ssh-keys-import";
  } do={
    $LogPrint warning $0 ("Failed importing key: " . $Err);
    $RmDir "tmpfs/ssh-keys-import";
    :return false;
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# import keys from a file
:set SSHKeysImportFile do={ :onerror Err {
  :local FileName [ :tostr $1 ];
  :local User     [ :tostr $2 ];

  :global EitherOr;
  :global FileExists;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global SSHKeysImport;

  :if ([ :len $FileName ] = 0 || [ :len $User ] = 0) do={
    $LogPrint warning $0 ("Missing argument(s), please pass file name and user!");
    :return false;
  }

  :if ([ $FileExists $FileName ] = false) do={
    $LogPrint warning $0 ("File '" . $FileName . "' does not exist.");
    :return false;
  }
  :local Keys [ :tolf [ /file/get $FileName contents ] ];

  :foreach KeyVal in=[ :deserialize $Keys delimiter=" " from=dsv options=dsv.plain ] do={
    :local Continue false;
    :if ($KeyVal->0 = "ssh-ed25519" || $KeyVal->0 = "ssh-rsa") do={
      :if ([ $SSHKeysImport ($KeyVal->0 . " " . $KeyVal->1 . " " . $KeyVal->2) $User ] = false) do={
        $LogPrint warning $0 ("Failed importing key for user '" . $User . "'.");
      }
      :set Continue true;
    }
    :if ($Continue = false && $KeyVal->0 = "#") do={
      :set User [ $EitherOr ([ $ParseKeyValueStore ($KeyVal->1) ]->"user") $User ];
      :set Continue true;
    }
    :if ($Continue = false && [ :len ($KeyVal->0) ] > 0) do={
      $LogPrint warning $0 ("SSH key of type '" . $KeyVal->0 . "' is not supported.");
    }
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }
