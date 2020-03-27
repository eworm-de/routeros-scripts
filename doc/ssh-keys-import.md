Import SSH keys
===============

[◀ Go back to main README](../README.md)

Description
-----------

This script imports public SSH keys (files with extension "`pub`") into
local store for user authentication.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate ssh-keys-import;

Usage and invocation
--------------------

Copy files with extension "`pub`" containing public SSH keys for your device.
Then run the script:

    / system script run ssh-keys-import;

Starting with an `authorized_keys` file you can split it on a shell:

    while read type key name; do echo $type $key $name > $name.pub; done < authorized_keys

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
