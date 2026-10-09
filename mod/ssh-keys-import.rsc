#!rsc by RouterOS
# RouterOS script: mod/ssh-keys-import
# Copyright (c) 2020-2026 Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
#
# import ssh keys for public key authentication
# https://rsc.eworm.de/doc/mod/ssh-keys-import.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=ssh-keys-import, schema=54cdcab8a420cb935136ec8a624f3eeceed166b6b96d7dd67b4ef7d0dcd74ea7
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"ssh-keys-import.arguments.file") "Missing argument(s), please pass file name and user!";
:set ($LanguageEnglish->"ssh-keys-import.arguments.key") "Missing argument(s), please pass key and user!";
:set ($LanguageEnglish->"ssh-keys-import.directory.failed") "Creating directory 'tmpfs/ssh-keys-import' failed!";
:set ($LanguageEnglish->"ssh-keys-import.file.missing") "File '{file}' does not exist.";
:set ($LanguageEnglish->"ssh-keys-import.import.failed") "Failed importing key: {error}";
:set ($LanguageEnglish->"ssh-keys-import.imported") "Imported ssh public key ({name}, {type}, MD5:{fingerprint}) for user '{user}'.";
:set ($LanguageEnglish->"ssh-keys-import.key.exists") "The ssh public key (MD5:{fingerprint}) is already available for user '{user}'.";
:set ($LanguageEnglish->"ssh-keys-import.type.unsupported") "SSH key of type '{type}' is not supported.";
:set ($LanguageEnglish->"ssh-keys-import.user.import.failed") "Failed importing key for user '{user}'.";
:set ($LanguageEnglish->"ssh-keys-import.user.missing") "User '{user}' does not exist.";
:set ($LanguageEnglish->"global-config.not.ready") "Global config and/or functions not ready.";
:global GlobalNotReadyMessage;
:if ([ :typeof $GlobalNotReadyMessage ] != "str") do={
  :set GlobalNotReadyMessage ($LanguageEnglish->"global-config.not.ready");
}
# END GENERATED LANGUAGE DATA

:global SSHKeysImport;
:global SSHKeysImportFile;

# import single key passed as string
:set SSHKeysImport do={ :onerror Err {
  :local Key  [ :tostr $1 ];
  :local User [ :tostr $2 ];

  :global GetRandom20CharAlNum;
  :global LogPrint;
  :global Translate;
  :global MkDir;
  :global RmDir;
  :global WaitForFile;

  :if ([ :len $Key ] = 0 || [ :len $User ] = 0) do={
    $LogPrint warning $0 [ $Translate "ssh-keys-import.arguments.key" ];
    :return false;
  }

  :if ([ :len [ /user/find where name=$User ] ] = 0) do={
    $LogPrint warning $0 [ $Translate "ssh-keys-import.user.missing" \
        ({ user=$User }) ];
    :return false;
  }

  :local KeyVal ([ :deserialize $Key delimiter=" " from=dsv options=dsv.plain ]->0);
  :if (!($KeyVal->0 = "ssh-ed25519" || $KeyVal->0 = "ssh-rsa")) do={
    $LogPrint warning $0 [ $Translate "ssh-keys-import.type.unsupported" \
        ({ type=($KeyVal->0) }) ];
    :return false;
  }

  :local FingerPrintMD5 [ :convert from=base64 transform=md5 to=hex ($KeyVal->1) ];

  :if ([ :len [ /user/ssh-keys/find where user=$User \
       info~("\\bmd5=" . $FingerPrintMD5 . "\\b") ] ] > 0) do={
    $LogPrint warning $0 [ $Translate "ssh-keys-import.key.exists" \
        ({ fingerprint=$FingerPrintMD5; user=$User }) ];
    :return false;
  }

  :if ([ $MkDir "tmpfs/ssh-keys-import" ] = false) do={
    $LogPrint warning $0 [ $Translate "ssh-keys-import.directory.failed" ];
    :return false;
  }

  :local FileName ("tmpfs/ssh-keys-import/key-" . [ $GetRandom20CharAlNum 6 ] . ".pub");
  /file/add name=$FileName contents=($Key . ", md5=" . $FingerPrintMD5);
  $WaitForFile $FileName;

  :onerror Err {
    /user/ssh-keys/import public-key-file=$FileName user=$User;
    $LogPrint info $0 [ $Translate "ssh-keys-import.imported" \
        ({ name=[ :tostr ($KeyVal->2) ]; type=($KeyVal->0); fingerprint=$FingerPrintMD5; user=$User }) ];
    $RmDir "tmpfs/ssh-keys-import";
  } do={
    $LogPrint warning $0 [ $Translate "ssh-keys-import.import.failed" \
        ({ error=$Err }) ];
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
  :global Translate;
  :global ParseKeyValueStore;
  :global SSHKeysImport;

  :if ([ :len $FileName ] = 0 || [ :len $User ] = 0) do={
    $LogPrint warning $0 [ $Translate "ssh-keys-import.arguments.file" ];
    :return false;
  }

  :if ([ $FileExists $FileName ] = false) do={
    $LogPrint warning $0 [ $Translate "ssh-keys-import.file.missing" \
        ({ file=$FileName }) ];
    :return false;
  }
  :local Keys [ :tolf [ /file/get $FileName contents ] ];

  :foreach KeyVal in=[ :deserialize $Keys delimiter=" " from=dsv options=dsv.plain ] do={
    :local Continue false;
    :if ($KeyVal->0 = "ssh-ed25519" || $KeyVal->0 = "ssh-rsa") do={
      :if ([ $SSHKeysImport ($KeyVal->0 . " " . $KeyVal->1 . " " . $KeyVal->2) $User ] = false) do={
        $LogPrint warning $0 [ $Translate "ssh-keys-import.user.import.failed" \
            ({ user=$User }) ];
      }
      :set Continue true;
    }
    :if ($Continue = false && $KeyVal->0 = "#") do={
      :set User [ $EitherOr ([ $ParseKeyValueStore ($KeyVal->1) ]->"user") $User ];
      :set Continue true;
    }
    :if ($Continue = false && [ :len ($KeyVal->0) ] > 0) do={
      $LogPrint warning $0 [ $Translate "ssh-keys-import.type.unsupported" \
          ({ type=($KeyVal->0) }) ];
    }
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }
