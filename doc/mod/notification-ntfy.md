Send notifications via Ntfy
===========================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.13-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds support for sending notifications via
[Ntfy](https://ntfy.sh/). A queue is used to make sure
notifications are not lost on failure but sent later.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/notification-ntfy;

Also install the Ntfy app on your mobile device or use the
[web app](https://ntfy.sh/app) in a browser of your choice.

Configuration
-------------

Creating an account is not required. Just choose a topic and you are good
to go.

> ⚠️ **Warning**: If you use ntfy without sign-up, the topic is essentially
> a password, so pick something that's not easily guessable.

Edit `global-config-overlay`, add `NtfyServer` (leave it unchanged, unless
you are self-hosting the service) and `NtfyTopic` with your choosen topic.
Then reload the configuration.

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Using a paid account or running a server on-premises allows to add additional
basic authentication. Configure `NtfyServerUser` and `NtfyServerPass` for this.
Even authentication via access token is possible, adding it as password with
a blank username.

Usage and invocation
--------------------

There's nothing special to do. Every script or function sending a notification
will now send it to your Ntfy topic.

But of course you can use the function to send notifications directly. Give
it a try:

    $SendNtfy "Subject..." "Body...";

Alternatively this sends a notification with all available and configured
methods:

    $SendNotification "Subject..." "Body...";

To use the functions in your own scripts you have to declare them first.
Place this before you call them:

    :global SendNtfy;
    :global SendNotification;

In case there is a situation when the queue needs to be purged there is a
function available:

    $PurgeNtfyQueue;

See also
--------

* [Send notifications via e-mail](notification-email.md)
* [Send notifications via Matrix](notification-matrix.md)
* [Send notifications via Telegram](notification-telegram.md)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
