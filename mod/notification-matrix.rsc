#!rsc by RouterOS
# RouterOS script: mod/notification-matrix
# Copyright (c) 2013-2026 Michael Gisbers <michael@gisbers.de>
#                         Christian Hesse <mail@eworm.de>
# https://rsc.eworm.de/COPYING.md
#
# requires RouterOS, version=7.22
# requires device-mode, fetch, scheduler
#
# send notifications via Matrix
# https://rsc.eworm.de/doc/mod/notification-matrix.md

# BEGIN GENERATED LANGUAGE DATA
# language, name=notification-matrix, schema=f843ad08937ad96c091b0aa66edd949e6e467c336607c9c73ff0270be3b95839
:global LanguageEnglish;
:if ([ :typeof $LanguageEnglish ] != "array") do={ :set LanguageEnglish ({}); }
:set ($LanguageEnglish->"notification-matrix.access.token") "Access token is: {token}";
:set ($LanguageEnglish->"notification-matrix.home.failed") "Failed getting home server: {error}";
:set ($LanguageEnglish->"notification-matrix.home.server") "Home server is: {server}";
:set ($LanguageEnglish->"notification-matrix.login.failed") "Failed logging in (and getting access token): {error}";
:set ($LanguageEnglish->"notification-matrix.offline") "System is not fully connected, not flushing.";
:set ($LanguageEnglish->"notification-matrix.queue.empty") "Flushing Matrix messages from scheduler, but queue is empty.";
:set ($LanguageEnglish->"notification-matrix.queue.failed") "Sending queued Matrix message failed: {error}";
:set ($LanguageEnglish->"notification-matrix.queued") "This message was queued since {date} and may be obsolete.";
:set ($LanguageEnglish->"notification-matrix.room.failed") "Failed joining the room: {error}";
:set ($LanguageEnglish->"notification-matrix.room.joined") "Joined the room.";
:set ($LanguageEnglish->"notification-matrix.send.failed") "Failed sending Matrix notification: {error} - Queuing...";
:set ($LanguageEnglish->"notification-matrix.snippet.added") "Added configuration snippet. Now create and join a room, please!";
:set ($LanguageEnglish->"notification-matrix.snippet.append.failed") "Failed appending configuration to snippet: {error}";
:set ($LanguageEnglish->"notification-matrix.snippet.appended") "Appended configuration to configuration snippet. Please review!";
:set ($LanguageEnglish->"notification-matrix.snippet.failed") "Failed adding configuration snippet: {error}";
# END GENERATED LANGUAGE DATA

:global FlushMatrixQueue;
:global NotificationFunctions;
:global PurgeMatrixQueue;
:global SendMatrix;
:global SendMatrix2;
:global SetupMatrixAuthenticate;
:global SetupMatrixJoinRoom;

# flush Matrix queue
:set FlushMatrixQueue do={ :onerror Err {
  :global MatrixQueue;

  :global IsFullyConnected;
  :global LogPrint;
  :global Translate;

  :if ([ $IsFullyConnected ] = false) do={
    $LogPrint debug $0 [ $Translate "notification-matrix.offline" ];
    :return false;
  }

  :local AllDone true;
  :local QueueLen [ :len $MatrixQueue ];

  :if ([ :len [ /system/scheduler/find where name="_FlushMatrixQueue" ] ] > 0 && $QueueLen = 0) do={
    $LogPrint warning $0 [ $Translate "notification-matrix.queue.empty" ];
  }

  :foreach Id,Message in=$MatrixQueue do={
    :if ([ :typeof $Message ] = "array" ) do={
      :onerror Err {
        /tool/fetch check-certificate=yes-without-crl output=none \
            http-header-field=($Message->"headers") http-method=post \
            http-data=[ :serialize to=json { "msgtype"="m.text"; "body"=($Message->"plain");
            "format"="org.matrix.custom.html"; "formatted_body"=($Message->"formatted") } ] \
            ("https://" . $Message->"homeserver" . "/_matrix/client/r0/rooms/" . $Message->"room" . \
            "/send/m.room.message?access_token=" . $Message->"accesstoken") as-value;
        :set ($MatrixQueue->$Id);
      } do={
        $LogPrint debug $0 [ $Translate "notification-matrix.queue.failed" \
            ({ error=$Err }) ];
        :set AllDone false;
      }
    }
  }

  :if ($AllDone = true && $QueueLen = [ :len $MatrixQueue ]) do={
    /system/scheduler/remove [ find where name="_FlushMatrixQueue" ];
    :set MatrixQueue;
  }
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# send notification via Matrix - expects one array argument
:set ($NotificationFunctions->"matrix") do={
  :local Notification $1;

  :global Identity;
  :global IdentityExtra;
  :global MatrixAccessToken;
  :global MatrixAccessTokenOverride;
  :global MatrixHomeServer;
  :global MatrixHomeServerOverride;
  :global MatrixQueue;
  :global MatrixRoom;
  :global MatrixRoomOverride;

  :global EitherOr;
  :global FetchUserAgentStr;
  :global LogPrint;
  :global Translate;
  :global ProtocolStrip;
  :global CharacterReplace;
  :global SymbolForNotification;

  :local PrepareText do={
    :local Input [ :tostr $1 ];

    :if ([ :len $Input ] = 0) do={
      :return "";
    }

    :local Return "";
    :local Chars { "\""; "\n"; "&"; "<"; ">" };
    :local Subs { "&quot;"; "<br/>"; "&amp;"; "&lt;"; "&gt;" };

    :for I from=0 to=([ :len $Input ] - 1) do={
      :local Char [ :pick $Input $I ];
      :local Replace [ :find $Chars $Char ];

      :if ([ :typeof $Replace ] = "num") do={
        :set Char ($Subs->$Replace);
      }
      :set Return ($Return . $Char);
    }

    :return $Return;
  }

  :local AccessToken [ $EitherOr ($MatrixAccessTokenOverride->($Notification->"origin")) $MatrixAccessToken ];
  :local HomeServer [ $EitherOr ($MatrixHomeServerOverride->($Notification->"origin")) $MatrixHomeServer ];
  :local Room [ $EitherOr ($MatrixRoomOverride->($Notification->"origin")) $MatrixRoom ];

  :if ([ :len $AccessToken ] = 0 || [ :len $HomeServer ] = 0 || [ :len $Room ] = 0) do={
    :return false;
  }

  :local Headers ({ [ $FetchUserAgentStr ($Notification->"origin") ] });
  :local Plain ("## [" . $IdentityExtra . $Identity . "] " . \
    ($Notification->"subject") . "\n```\n" . ($Notification->"message") . "\n```");
  :local Formatted ("<h2>" . [ $PrepareText ("[" . $IdentityExtra . $Identity . "] " . \
    ($Notification->"subject")) ] . "</h2>" . "<pre><code>" . \
    [ $PrepareText ($Notification->"message") ] . "</code></pre>");
  :if ([ :len ($Notification->"link") ] > 0) do={
    :local Label [ $ProtocolStrip ($Notification->"link") ];
    :set Plain ($Plain . "\n" . [ $SymbolForNotification "link" ] . \
      "[" . $Label . "](" . $Notification->"link" . ")");
    :set Formatted ($Formatted . "<br/>" . [ $SymbolForNotification "link" ] . \
      "<a href=\"" . [ $PrepareText ($Notification->"link") ] . "\">" . \
      [ $PrepareText $Label ] . "</a>");
  }

  :onerror Err {
    /tool/fetch check-certificate=yes-without-crl output=none \
        http-header-field=$Headers http-method=post \
        http-data=[ :serialize to=json { "msgtype"="m.text"; "body"=$Plain;
        "format"="org.matrix.custom.html"; "formatted_body"=$Formatted } ] \
        ("https://" . $HomeServer . "/_matrix/client/r0/rooms/" . $Room . \
        "/send/m.room.message?access_token=" . $AccessToken) as-value;
  } do={
    $LogPrint info $0 [ $Translate "notification-matrix.send.failed" \
        ({ error=$Err }) ];

    :if ([ :typeof $MatrixQueue ] = "nothing") do={
      :set MatrixQueue ({});
    }
    :local Symbol [ $SymbolForNotification "alarm-clock" ];
    :local DateTime ([ /system/clock/get date ] . " " . [ /system/clock/get time ]);
    :set Plain ($Plain . "\n" . $Symbol . [ $Translate "notification-matrix.queued" \
        ({ date=("*" . $DateTime . "*") }) ]);
    :local Queued [ $PrepareText [ $Translate "notification-matrix.queued" \
        ({ date=$DateTime }) ] ];
    :set Queued [ $CharacterReplace $Queued [ $PrepareText $DateTime ] \
        ("<em>" . [ $PrepareText $DateTime ] . "</em>") ];
    :set Formatted ($Formatted . "<br/>" . $Symbol . $Queued);
    :set ($MatrixQueue->[ :len $MatrixQueue ]) { headers=$Headers; \
        accesstoken=$AccessToken; homeserver=$HomeServer; room=$Room; \
        plain=$Plain; formatted=$Formatted };
    :if ([ :len [ /system/scheduler/find where name="_FlushMatrixQueue" ] ] = 0) do={
      /system/scheduler/add name="_FlushMatrixQueue" interval=1m start-time=startup \
        on-event=(":global FlushMatrixQueue; \$FlushMatrixQueue;");
    }
  }
}

# purge the Matrix queue
:set PurgeMatrixQueue do={
  :global MatrixQueue;

  /system/scheduler/remove [ find where name="_FlushMatrixQueue" ];
  :set MatrixQueue;
}

# send notification via Matrix - expects at least two string arguments
:set SendMatrix do={ :onerror Err {
  :global SendMatrix2;

  $SendMatrix2 ({ origin=$0; subject=$1; message=$2; link=$3 });
} do={
  :global ExitOnError; $ExitOnError $0 $Err;
} }

# send notification via Matrix - expects one array argument
:set SendMatrix2 do={
  :local Notification $1;

  :global NotificationFunctions;

  ($NotificationFunctions->"matrix") ("\$NotificationFunctions->\"matrix\"") $Notification;
}

# setup - get home server and access token
:set SetupMatrixAuthenticate do={
  :local User [ :tostr $1 ];
  :local Pass [ :tostr $2 ];

  :global FetchUserAgentStr;
  :global LogPrint;
  :global Translate;

  :global MatrixAccessToken;
  :global MatrixHomeServer;

  :local Domain [ :pick $User ([ :find $User ":" ] + 1) [ :len $User] ];
  :onerror Err {
    :local Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
        http-header-field=({ [ $FetchUserAgentStr $0 ] }) \
        ("https://" . $Domain . "/.well-known/matrix/client") as-value ]->"data");
    :set MatrixHomeServer ([ :deserialize from=json value=$Data ]->"m.homeserver"->"base_url");
    $LogPrint debug $0 [ $Translate "notification-matrix.home.server" \
        ({ server=$MatrixHomeServer }) ];
  } do={
    $LogPrint error $0 [ $Translate "notification-matrix.home.failed" \
        ({ error=$Err }) ];
    :return false;
  }

  :if ([ :pick $MatrixHomeServer 0 8 ] = "https://") do={
    :set MatrixHomeServer [ :pick $MatrixHomeServer 8 [ :len $MatrixHomeServer ] ];
  }

  :onerror Err {
    :local Data ([ /tool/fetch check-certificate=yes-without-crl output=user \
        http-header-field=({ [ $FetchUserAgentStr $0 ] }) http-method=post \
        http-data=[ :serialize to=json { "type"="m.login.password"; "user"=$User; "password"=$Pass } ] \
        ("https://" . $MatrixHomeServer . "/_matrix/client/r0/login") as-value ]->"data");
    :set MatrixAccessToken ([ :deserialize from=json value=$Data ]->"access_token");
    $LogPrint debug $0 [ $Translate "notification-matrix.access.token" \
        ({ token=$MatrixAccessToken }) ];
  } do={
    $LogPrint error $0 [ $Translate "notification-matrix.login.failed" \
        ({ error=$Err }) ];
    :return false;
  }

  :onerror Err {
    /system/script/remove [ find where name="global-config-overlay.d/mod/notification-matrix" ];
    /system/script/add name="global-config-overlay.d/mod/notification-matrix" source=( \
      "# configuration snippet: mod/notification-matrix\n\n" . \
      ":global MatrixHomeServer \"" . $MatrixHomeServer . "\";\n" . \
      ":global MatrixAccessToken \"" . $MatrixAccessToken . "\";\n");
    $LogPrint info $0 [ $Translate "notification-matrix.snippet.added" ];
  } do={
    $LogPrint error $0 [ $Translate "notification-matrix.snippet.failed" \
        ({ error=$Err }) ];
    :return false;
  }
}

# setup - join a room
:set SetupMatrixJoinRoom do={
  :global MatrixRoom [ :tostr $1 ];

  :global FetchUserAgentStr;
  :global LogPrint;
  :global Translate;

  :global MatrixAccessToken;
  :global MatrixHomeServer;
  :global MatrixRoom;

  :onerror Err {
    /tool/fetch check-certificate=yes-without-crl output=none \
        http-header-field=({ [ $FetchUserAgentStr $0 ] }) http-method=post http-data="" \
        ("https://" . $MatrixHomeServer . "/_matrix/client/r0/rooms/" . [ :convert to=url $MatrixRoom ] . \
        "/join?access_token=" . [ :convert to=url $MatrixAccessToken ]) as-value;
    $LogPrint debug $0 [ $Translate "notification-matrix.room.joined" ];
  } do={
    $LogPrint error $0 [ $Translate "notification-matrix.room.failed" \
        ({ error=$Err }) ];
    :return false;
  }

  :onerror Err {
    :local Snippet [ /system/script/find where name="global-config-overlay.d/mod/notification-matrix" ];
    /system/script/set $Snippet source=([ get $Snippet source ] . \
      ":global MatrixRoom \"" . $MatrixRoom . "\";\n");
    $LogPrint info $0 [ $Translate "notification-matrix.snippet.appended" ];
  } do={
    $LogPrint error $0 [ $Translate "notification-matrix.snippet.append.failed" \
        ({ error=$Err }) ];
    :return false;
  }
}
