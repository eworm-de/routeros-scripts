Installing from branches
========================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.17-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](README.md)

> ⚠️ **Warning**: Living on the edge? Great, read on!
> If not: Please use the `main` branch and leave this page!

These scripts are developed in a [git ↗️](https://git-scm.com/) repository.
Development and experimental branches are used to provide early access
for specific changes. You can install scripts from these branches
for testing.

## Install single script

To install a single script from `next` branch:

    $ScriptInstallUpdate script-name "base-url=https://rsc.eworm.de/next/";

## Switch existing script

Alternatively switch an existing script to update from `next` branch:

    /system/script/set comment="base-url=https://rsc.eworm.de/next/" script-name;
    $ScriptInstallUpdate;

## Switch installation

Last but not least - to switch the complete installation to the `next`
branch edit `global-config-overlay` and add:

    :global ScriptUpdatesBaseUrl "https://rsc.eworm.de/next/";

... then reload the configuration and update:

    /system/script/run global-config;
    $ScriptInstallUpdate;

> ℹ️ **Info**: Replace `next` with *whatever* to use another specific branch.

---
[⬅️ Go back to main README](README.md)  
[⬆️ Go back to top](#top)
