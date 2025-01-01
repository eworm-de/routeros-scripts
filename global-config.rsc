#!rsc by RouterOS
# RouterOS script: global-config
# Copyright (c) 2013-2025 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md
#
# global configuration
# https://git.eworm.de/cgit/routeros-scripts/about/

# Set this to 'true' to disable news and change notifications.
:global NoNewsAndChangesNotification false;

# Add extra text (or emojis) in notification tags.
:global IdentityExtra "";

# This is used in DNS scripts ('ipsec-to-dns' and fallback in 'dhcp-to-dns')
# and backup scripts for file names.
:global Domain "example.com";

# You can send e-mail notifications. Configure the system's mail settings
# (/tool/e-mail), then install the module:
# $ScriptInstallUpdate mod/notification-email
# The to-address needs to be filled; cc-address can be empty, one address
# or a comma separated list of addresses.
:global EmailGeneralTo "";
:global EmailGeneralCc "";
#:global EmailGeneralTo "mail@example.com";
#:global EmailGeneralCc "another@example.com,third@example.com";

# You can send Telegram notifications. Register a bot
# and add the token and chat ids here, then install the module:
# $ScriptInstallUpdate mod/notification-telegram
:global TelegramTokenId "";
:global TelegramChatId "";
#:global TelegramTokenId "123456:ABCDEF-GHI";
#:global TelegramChatId "12345678";
# Using telegram-chat you have to define trusted chat ids (not group ids!)
# or user names. Groups allow to chat with devices simultaneously.
#:global TelegramChatIdsTrusted {
#  "12345678";
#  "example_user";
#};
:global TelegramChatGroups "(all)";
#:global TelegramChatGroups "(all|home|office)";

# You can send Matrix notifications. Configure these settings and
# install the module:
# $ScriptInstallUpdate mod/notification-matrix
:global MatrixHomeServer "";
:global MatrixAccessToken "";
:global MatrixRoom "";
#:global MatrixHomeServer "matrix.org";
#:global MatrixAccessToken "123456ABCDEFGHI...";
#:global MatrixRoom "!example:matrix.org";

# You can send Ntfy notifications. Configure these settings and
# install the module:
# $ScriptInstallUpdate mod/notification-ntfy
:global NtfyServer "ntfy.sh";
:global NtfyServerUser [];
:global NtfyServerPass [];
:global NtfyServerToken [];
:global NtfyTopic "";

# It is possible to override e-mail, Telegram, Matrix and Ntfy setting
# for every script. This is done in arrays, where 'Override' is appended
# to the variable name, like this:
#:global EmailGeneralToOverride {
#  "check-certificates"="override@example.com";
#  "backup-email"="backup@example.com";
#}

# Toggle this to disable symbols in notifications.
:global NotificationsWithSymbols true;
# Toggle this to disable color output in terminal/cli.
:global TerminalColorOutput true;

# This defines what backups to generate and what password to use.
:global BackupSendBinary false;
:global BackupSendExport true;
:global BackupSendGlobalConfig true;
:global BackupPassword "v3ry-s3cr3t";
:global BackupRandomDelay 0;
# These credentials are used to upload backup and config export files.
# SFTP authentication is tricky, you may have to limit authentication
# methods for your SSH server.
:global BackupUploadUrl "sftp://example.com/backup/";
:global BackupUploadUser "mikrotik";
:global BackupUploadPass "v3ry-s3cr3t";
# Copy the RouterOS installation to backup partition before feature update.
:global BackupPartitionCopyBeforeFeatureUpdate false;

# This defines the settings for firewall address-lists (fw-addr-lists).
:global FwAddrLists {
#  "allow"={
#    { url="https://git.eworm.de/cgit/routeros-scripts/plain/fw-addr-lists.d/allow";
#      cert="ISRG Root X2"; timeout=1w };
#  };
  "block"={
#    { url="https://git.eworm.de/cgit/routeros-scripts/plain/fw-addr-lists.d/block";
#      cert="ISRG Root X2" };
    { url="https://feodotracker.abuse.ch/downloads/ipblocklist_recommended.txt";
      cert="GlobalSign" };
    { url="https://sslbl.abuse.ch/blacklist/sslipblacklist.txt";
      cert="GlobalSign" };
    { url="https://www.dshield.org/block.txt"; cidr="/24";
      cert="ISRG Root X1" };
    { url="https://lists.blocklist.de/lists/strongips.txt";
      cert="Certum Trusted Network CA" };
#    { url="https://www.spamhaus.org/drop/drop_v4.json";
#      cert="ISRG Root X1" };
#    { url="https://www.spamhaus.org/drop/drop_v6.json";
#      cert="ISRG Root X1" };
  };
#  "mikrotik"={
#    { url="https://git.eworm.de/cgit/routeros-scripts/plain/fw-addr-lists.d/mikrotik";
#      cert="ISRG Root X2"; timeout=1w };
#  };
};
:global FwAddrListTimeOut 1d;

# This defines what log messages to filter or include by topic or message
# text. Regular expressions are supported. Do *NOT* set an empty string,
# that will filter or include everything!
# These are filters, so excluding messages from forwarding.
:global LogForwardFilter "(debug|info|packet|raw)";
:global LogForwardFilterMessage [];
#:global LogForwardFilterMessage "message text";
#:global LogForwardFilterMessage "(message text|another text|...)";
# ... and another setting with reverse logic. This includes messages even
# if filtered above.
:global LogForwardInclude [];
:global LogForwardIncludeMessage [];
#:global LogForwardInclude "account";
#:global LogForwardIncludeMessage "message text";

# Specify an address to enable auto update to version assumed safe.
# The configured channel (bugfix, current, release-candidate) is appended.
:global SafeUpdateUrl "";
#:global SafeUpdateUrl "https://example.com/ros/safe-update/";
# Allow to install patch updates automatically.
:global SafeUpdatePatch false;
# Allow to install updates automatically if seen in neighbor list.
:global SafeUpdateNeighbor false;
:global SafeUpdateNeighborIdentity "";
# Install *ALL* updates automatically!
# Set to all upper-case "Yes, please!" to enable.
:global SafeUpdateAll "no";

# Defer the reboot for night on automatic (non-interactive) update
:global PackagesUpdateDeferReboot false;

# These thresholds control when to send health notification
# on temperature and voltage.
:global CheckHealthTemperature {
  temperature=50;
  cpu-temperature=70;
  board-temperature1=50;
  board-temperature2=50;
};
# This is deviation on recovery threshold against notification flooding.
:global CheckHealthTemperatureDeviation 3;
:global CheckHealthVoltageLow 115;
:global CheckHealthVoltagePercent 10;

# Access-list entries matching this comment are updated
# with daily pseudo-random PSK.
:global DailyPskMatchComment "Daily PSK";
:global DailyPskQrCodeUrl "https://www.eworm.de/cgi-bin/cqrlogo-wifi.cgi";
:global DailyPskSecrets {
  { "Abusive"; "Aggressive"; "Bored"; "Chemical"; "Cold";
    "Cruel"; "Curved"; "Delightful"; "Discreet"; "Elite";
    "Evasive"; "Faded"; "Flat"; "Future"; "Grandiose";
    "Hanging"; "Humorous"; "Interesting"; "Magenta";
    "Magnificent"; "Numerous"; "Optimal"; "Pathetic";
    "Possessive"; "Remarkable"; "Rightful"; "Ruthless";
    "Stale"; "Unusual"; "Useless"; "Various" };
  { "Adhesive"; "Amusing"; "Astonishing"; "Frantic";
    "Kindhearted"; "Limping"; "Roasted"; "Robust";
    "Staking"; "Thundering"; "Ultra"; "Unreal" };
  { "Belief"; "Button"; "Curtain"; "Edge"; "Jewel";
    "String"; "Whistle" }
};

# Specify how to assemble DNS names in ipsec-to-dns.
:global HostNameInZone true;
:global PrefixInZone true;

# Run different commands with multiple mode-button presses.
:global ModeButton {
  1="/system/leds/settings/set all-leds-off=(({ \"never\"=\"immediate\"; \"immediate\"=\"never\" })->[ get all-leds-off ]);";
  2=":global Identity; :global SendNotification; :global SymbolForNotification; \$SendNotification ([ \$SymbolForNotification \"earth\" ] . \"Hello...\") (\"Hello world, \" . \$Identity . \" calling!\");";
  3="/system/shutdown;";
  4="/system/reboot;";
  5=":global BridgePortVlan; \$BridgePortVlan alt;";
# add more here...
};
# This led gives visual feedback if type is 'on' or 'off'.
:global ModeButtonLED "user-led";

# Run commands on SMS action.
:global SmsAction {
  bridge-port-vlan-alt=":global BridgePortVlan; \$BridgePortVlan alt;";
  reboot="/system/reboot;";
  shutdown="/system/shutdown;";
# add more here...
};

# Run commands by hooking into SMS forward.
:global SmsForwardHooks {
  { match="magic string";
    allowed-number="12345678";
    command="/system/script/run ..." };
# add more here...
};

# This is the address used to send gps data to.
:global GpsTrackUrl "https://example.com/index.php";

# This is the base url to fetch scripts from.
:global ScriptUpdatesBaseUrl "https://git.eworm.de/cgit/routeros-scripts/plain/";
# alternative urls - main: stable code - next: currently in development
#:global ScriptUpdatesBaseUrl "https://raw.githubusercontent.com/eworm-de/routeros-scripts/main/";
#:global ScriptUpdatesBaseUrl "https://raw.githubusercontent.com/eworm-de/routeros-scripts/next/";
#:global ScriptUpdatesBaseUrl "https://gitlab.com/eworm-de/routeros-scripts/raw/main/";
#:global ScriptUpdatesBaseUrl "https://gitlab.com/eworm-de/routeros-scripts/raw/next/";
:global ScriptUpdatesUrlSuffix "";
# use next branch with default url (git.eworm.de)
#:global ScriptUpdatesUrlSuffix "?h=next";

# Use this for defaults with $ScriptRunOnce
# Install module with:
# $ScriptInstallUpdate mod/scriptrunonce
:global ScriptRunOnceBaseUrl "";
:global ScriptRunOnceUrlSuffix "";

# This project is developed in private spare time and usage is free of charge
# for you. If you like the scripts and think this is of value for you or your
# business please consider a donation:
# https://git.eworm.de/cgit/routeros-scripts/about/#donate
# Enable this to silence donation hint.
:global IDonate false;

# Use this for certificate auto-renew
:global CertRenewUrl "";
#:global CertRenewUrl "https://example.com/certificates/";
:global CertRenewTime 3w;
:global CertRenewPass {
  "v3ry-s3cr3t";
  "4n0th3r-s3cr3t";
};
:global CertWarnTime 2w;
:global CertIssuedExportPass {
  "cert1-cn"="v3ry-s3cr3t";
  "cert2-cn"="4n0th3r-s3cr3t";
};

# load custom settings from overlay and snippets
# Warning: Do *NOT* copy this code to overlay!
:foreach Script in=([ /system/script/find where name="global-config-overlay" ], \
                    [ /system/script/find where name~"^global-config-overlay.d/" ]) do={
  :do {
    /system/script/run $Script;
  } on-error={
    :log error ("Loading configuration from overlay or snippet " . \
        [ /system/script/get $Script name ] . " failed!");
  }
}
