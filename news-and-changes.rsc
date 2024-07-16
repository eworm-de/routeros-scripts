# News, changes and migration by RouterOS Scripts
# Copyright (c) 2019-2024 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md

:global IDonate;

:global IfThenElse;
:global RequiredRouterOS;
:global SymbolForNotification;

:local Resource [ /system/resource/get ];

# News, changes and migration up to change 95:
# https://git.eworm.de/cgit/routeros-scripts/plain/global-config.changes?h=change-95

# Changes for global-config to be added to notification on script updates
:global GlobalConfigChanges {
  96="Added support for notes in 'netwatch-notify', these are included verbatim into the notification.";
  97="Modified 'dhcp-to-dns' to always add A records for names with mac address, and optionally add CNAME records if the host name is available.";
  98="Extended 'check-certificates' to download new certificate by SubjectAltNames if download by CommonName fails.";
  99="Modified 'dhcp-to-dns', which dropped global configuration. Settings moved to dhcp server's network definitions.";
  100="The script 'ssh-keys-import' became a module 'mod/ssh-keys-import' with enhanced functionality.";
  101="Introduced new script 'fw-addr-lists' to download, import and update firewall address-lists.";
  102="Modified 'hotspot-to-wpa' to support non-local (radius) users.";
  103="Dropped hard-coded name and timeout from 'hotspot-to-wpa-cleanup', instead a comment is required for dhcp server now.";
  104="All relevant scripts were ported to new wifiwave2 and are available for AX devices now!";
  105="Extended 'check-routeros-update' to support automatic update from specific neighbor(s).";
  106="Modified 'telegram-chat' to make it act on message replies, without activation. Also made it answer a single question mark with a short notice.";
  107="Dropped support for non-fixed width font in Telegram notifications.";
  108="Enhanced 'log-forward' to list log messages with colorful bullets to indicate severity.";
  109="Added support to send notifications via Ntfy (ntfy.sh).";
  110="Dropped support for loading scripts from local storage.";
  111="Modified 'dhcp-to-dns' to allow multiple records for one mac address.";
  112="Enhanced 'mod/ssh-keys-import' to record the fingerprint of keys.";
  113="Added helper functions for easier setup to Matrix notification module.";
  114="All relevant scripts were ported to new wifi package for RouterOS 7.13 and later. Migration is complex and thus not done automatically!";
  115=("Celebrating " . [ $SymbolForNotification "sparkles,star" ] . "1.000 stars " . [ $SymbolForNotification "star,sparkles" ] . "on Github! Please continue starring...");
  116=("... and also please keep in mind that it takes a huge amount of time maintaining these scripts. " . [ $IfThenElse ($IDonate != true) \
        ("Following the donation hint " . [ $SymbolForNotification "arrow-down" "below" ] . "to keep me motivated is much appreciated. Thanks!") \
        ("Looks like you did donate already. " . [ $SymbolForNotification "heart" "<3" ] . "Much appreciated, thanks!") ]);
  117="Enhanced 'packages-update' to support deferred reboot on automatically installed updates.";
  118=("RouterOS packages increase in size with each release. This becomes a problem for devices with 16MB storage and below. " . \
        [ $IfThenElse ($Resource->"total-hdd-space" < 16000000) ("Your " . $Resource->"board-name" . " is specifically affected! ") \
        [ $IfThenElse ($Resource->"free-hdd-space" > 4000000) ("(Your " . $Resource->"board-name" . " does not suffer this issue.) ") ] ] . \
        "Huge configuration and lots of scripts give an extra risk. Take care!");
  119="Added support for IPv6 to script 'fw-addr-lists'.";
  120="Implemented a workaround in 'backup-cloud'. Now script should no longer just crash, but send notification with error.";
  121="The 'wifiwave2' scripts are finally gone. Development continues with 'wifi' in RouterOS 7.13 and later.";
  122="The global configuration was enhanced to support loading snippets. Configuration can be split off to scripts where name starts with 'global-config-overlay.d/'.";
  123="Introduced new function '\$LogPrint', and deprecated '\$LogPrintExit2'. Please update custom scripts if you use it.";
  124="Added support for links in 'netwatch-notify', these are added below the formatted notification text.";
  125=("April's Fool! " . [ $SymbolForNotification "smiley-partying-face" ] . "Well, you missed it... - no charge nor fees. (Anyway... Donations are much appreciated, " . [ $SymbolForNotification "smiley-smiling-face" ] . "thanks!)");
  126="Made 'telegram-chat' capable of handling large command output. Telegram messages still limit the size, so it is truncated now.";
  127="Added support for authentication to Ntfy notification module.";
  128="Added another list from blocklist.de to default configuration for 'fw-addr-lists'.";
  129="Extended 'backup-partition' to support RouterOS copy-over - interactively or before feature update.";
  130="Dropped intermediate certificates, depending on just root certificates now.";
  131="Enhanced certificate download to fallback to mkcert.org, so all (commonly trusted) root certificates are available now.";
};

# Migration steps to be applied on script updates
:global GlobalConfigMigration {
  97=":local Rec [ /ip/dns/static/find where comment~\"^managed by dhcp-to-dns for \" ]; :if ([ :len \$Rec ] > 0) do={ /ip/dns/static/remove \$Rec; /system/script/run dhcp-to-dns; }";
  100=":global ScriptInstallUpdate; :if ([ :len [ /system/script/find where name=\"ssh-keys-import\" source~\"^#!rsc by RouterOS\\r?\\n\" ] ] > 0) do={ /system/script/set name=\"mod/ssh-keys-import\" ssh-keys-import; \$ScriptInstallUpdate; }";
  104=":global CharacterReplace; :global ScriptInstallUpdate; :foreach Script in={ \"capsman-download-packages\"; \"capsman-rolling-upgrade\"; \"hotspot-to-wpa\"; \"hotspot-to-wpa-cleanup\" } do={ /system/script/set name=(\$Script . \".capsman\") [ find where name=\$Script ]; :foreach Scheduler in=[ /system/scheduler/find where on-event~(\$Script . \"([^-.]|\\\$)\") ] do={ /system/scheduler/set \$Scheduler on-event=[ \$CharacterReplace [ get \$Scheduler on-event ] \$Script (\$Script . \".capsman\") ]; }; }; /ip/hotspot/user/profile/set on-login=\"hotspot-to-wpa.capsman\" [ find where on-login=\"hotspot-to-wpa\" ]; \$ScriptInstallUpdate;";
  111=":local Rec [ /ip/dns/static/find where comment~\"^managed by dhcp-to-dns for \" ]; :if ([ :len \$Rec ] > 0) do={ /ip/dns/static/remove \$Rec; /system/script/run dhcp-to-dns; }";
};
