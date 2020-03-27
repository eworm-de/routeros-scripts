Find and remove access list duplicates
======================================

[◀ Go back to main README](../README.md)

Description
-----------

This script is supposed to run interactively to find and remove duplicate
entries in wireless access list.

Requirements and installation
-----------------------------

Depending on whether you use CAPsMAN (`/ caps-man`) or local wireless
interface (`/ interface wireless`) you need to install a different script.

For CAPsMAN:

    $ScriptInstallUpdate accesslist-duplicates.capsman;

For local interface:

    $ScriptInstallUpdate accesslist-duplicates.local;

Usage and invocation
--------------------

Run this script from a terminal:

    [admin@kalyke] > / system script run accesslist-duplicates.local
    Flags: X - disabled
     0   ;;; First entry with identical mac address...
         mac-address=00:11:22:33:44:55 interface=any signal-range=-120..120 allow-signal-out-of-range=10s authentication=yes forwarding=yes ap-tx-limit=0 client-tx-limit=0 private-algo=none private-key="" private-pre-shared-key=""  management-protection-key="" vlan-mode=default vlan-id=1

     1   ;;; Second entry with identical mac address...
         mac-address=00:11:22:33:44:55 interface=any signal-range=-120..120 allow-signal-out-of-range=10s authentication=yes forwarding=yes ap-tx-limit=0 client-tx-limit=0 private-algo=none private-key="" private-pre-shared-key="" management-protection-key="" vlan-mode=default vlan-id=1

    Numeric id to remove, any key to skip!
    Removing numeric id 1...

See also
--------

* [Collect MAC addresses in wireless access list](collect-wireless-mac.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
