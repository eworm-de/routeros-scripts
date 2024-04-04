#!rsc by RouterOS
# RouterOS script: mod/ssh-keys-import
# Copyright (c) 2020-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# requires RouterOS, version=7.13
#
# import ssh keys for public key authentication
# https://git.eworm.de/cgit/routeros-scripts/about/doc/mod/ssh-keys-import.md

:global SSHKeysImport;
:global SSHKeysImportFile;

# import single key passed as string
:set SSHKeysImport do={
  :local Key  [ :tostr $1 ];
  :local User [ :tostr $2 ];

  :global CharacterReplace;
  :global GetRandom20CharAlNum;
  :global LogPrint;
  :global MkDir;
  :global WaitForFile;

  :if ([ :len $Key ] = 0 || [ :len $User ] = 0) do={
    $LogPrint warning $0 ("Missing argument(s), please pass key and user!");
    :return false;
  }

  :if ([ :len [ /user/find where name=$User ] ] = 0) do={
    $LogPrint warning $0 ("User '" . $User . "' does not exist.");
    :return false;
  }

  :local KeyVal [ :toarray [ $CharacterReplace $Key " " "," ] ];
  :if (!($KeyVal->0 = "ssh-ed25519" || $KeyVal->0 = "ssh-rsa")) do={
    $LogPrint warning $0 ("SSH key of type '" . $KeyVal->0 . "' is not supported.");
    :return false;
  }

  :if ([ $MkDir "tmpfs/ssh-keys-import" ] = false) do={
    $LogPrint warning $0 ("Creating directory 'tmpfs/ssh-keys-import' failed!");
    :return false;
  }

  :local FingerPrintMD5 [ :convert from=base64 transform=md5 to=hex ($KeyVal->1) ];

  :if ([ :len [ /user/ssh-keys/find where user=$User key-owner~("\\bmd5=" . $FingerPrintMD5 . "\\b") ] ] > 0) do={
    $LogPrint warning $0 ("The ssh public key (MD5:" . $FingerPrintMD5 . \
      ") is already available for user '" . $User . "'.");
    :return false;
  }

  :local FileName ("tmpfs/ssh-keys-import/key-" . [ $GetRandom20CharAlNum 6 ] . ".pub");
  /file/add name=$FileName contents=($Key . ", md5=" . $FingerPrintMD5);
  $WaitForFile $FileName;

  :do {
    /user/ssh-keys/import public-key-file=$FileName user=$User;
    $LogPrint info $0 ("Imported ssh public key (" . $KeyVal->2 . ", " . $KeyVal->0 . ", " . \
      "MD5:" . $FingerPrintMD5 . ") for user '" . $User . "'.");
  } on-error={
    $LogPrint warning $0 ("Failed importing key.");
    :return false;
  }
}

# import keys from a file
:set SSHKeysImportFile do={
  :local FileName [ :tostr $1 ];
  :local User     [ :tostr $2 ];

  :global CharacterReplace;
  :global EitherOr;
  :global LogPrint;
  :global ParseKeyValueStore;
  :global SSHKeysImport;

  :if ([ :len $FileName ] = 0 || [ :len $User ] = 0) do={
    $LogPrint warning $0 ("Missing argument(s), please pass file name and user!");
    :return false;
  }

  :local File [ /file/find where name=$FileName ];
  :if ([ :len $File ] = 0) do={
    $LogPrint warning $0 ("File '" . $FileName . "' does not exist.");
    :return false;
  }
  :local Keys ([ /file/get $FileName contents ] . "\n");

  :do {
    :local Continue false;
    :local Line [ :pick $Keys 0 [ :find $Keys "\n" ] ];
    :set Keys [ :pick $Keys ([ :find $Keys "\n" ] + 1) [ :len $Keys ] ];
    :local KeyVal [ :toarray [ $CharacterReplace $Line " " "," ] ];
    :if ($KeyVal->0 = "ssh-ed25519" || $KeyVal->0 = "ssh-rsa") do={
      :do {
        $SSHKeysImport $Line $User;
      } on-error={
        $LogPrint warning $0 ("Failed importing key for user '" . $User . "'.");
      }
      :set Continue true;
    }
    :if ($Continue = false && $KeyVal->0 = "#") do={
      :set User [ $EitherOr ([ $ParseKeyValueStore [ :pick $Line 2 [ :len $Line ] ] ]->"user") $User ];
      :set Continue true;
    }
    :if ($Continue = false && [ :len ($KeyVal->0) ] > 0) do={
      $LogPrint warning $0 ("SSH key of type '" . $KeyVal->0 . "' is not supported.");
    }
  } while=([ :len $Keys ] > 0);
}
