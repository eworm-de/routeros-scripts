# News, changes and migration by RouterOS Scripts
# Copyright (c) 2019-2023 Christian Hesse <mail@eworm.de>
# https://git.eworm.de/cgit/routeros-scripts/about/COPYING.md

:global IfThenElse;
:global RequiredRouterOS;

# News, changes and migration up to change 95 are in global-config.changes!

# Changes for global-config to be added to notification on script updates
:global GlobalConfigChanges {
  96="Added support for notes in 'netwatch-notify', these are included verbatim into the notification.";
  97="Modified 'dhcp-to-dns' to always add A records for names with mac address, and optionally add CNAME records if the host name is available.";
  98="Extended 'check-certificates' to download new certificate by SubjectAltNames if download by CommonName fails.";
  99="Modified 'dhcp-to-dns', which dropped global configuration. Settings moved to dhcp server's network definitions.";
  100="The script 'ssh-keys-import' became a module 'mod/ssh-keys-import' with enhanced functionality.";
  101="Introduced new script 'fw-addr-lists' to download, import and update firewall address-lists.";
  102="Modified 'hotspot-to-wpa' to support non-local (radius) users.";
  103="Dropped hard-coded name from 'hotspot-to-wpa-cleanup', instead a comment is required for dhcp server now.";
};

# Migration steps to be applied on script updates
:global GlobalConfigMigration {
  97=":local Rec [ /ip/dns/static/find where comment~\"^managed by dhcp-to-dns for \" ]; :if ([ :len \$Rec ] > 0) do={ /ip/dns/static/remove \$Rec; /system/script/run dhcp-to-dns; }";
  100=":global ScriptInstallUpdate; :if ([ :len [ /system/script/find where name=\"ssh-keys-import\" source~\"^#!rsc by RouterOS\\n\" ] ] > 0) do={ /system/script/set name=\"mod/ssh-keys-import\" ssh-keys-import; \$ScriptInstallUpdate; }";
};
