Installing from branches
========================

[⬅️ Go back to main README](README.md)

> ⚠️ **Warning**: Living on the edge? Great, read on!
> If not: Please use the `main` branch and leave this page!

These scripts are developed in a [git](https://git-scm.com/) repository.
Development and experimental branches are used to provide early access
for specific changes. You can install scripts from these branches
for testing.

## Install single script

To install a single script from `next` branch:

    $ScriptInstallUpdate script-name "url-suffix=?h=next";

## Switch existing script

Alternatively switch an existing script to update from `next` branch:

    /system/script/set comment="url-suffix=?h=next" script-name;
    $ScriptInstallUpdate;

## Switch installation

Last but not least - to switch the complete installation to the `next`
branch edit `global-config-overlay` and add:

    :global ScriptUpdatesUrlSuffix "?h=next";

... then reload the configuration and update:

    /system/script/run global-config;
    $ScriptInstallUpdate;

> ℹ️ **Info**: Replace `next` with *whatever* to use another specific branch.

---
[⬅️ Go back to main README](README.md)  
[⬆️ Go back to top](#top)
