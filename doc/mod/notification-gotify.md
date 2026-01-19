Send notifications via Gotify
===========================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.19-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds support for sending notifications via
[Gotify ↗️](https://gotify.net/). A queue is used to make sure
notifications are not lost on failure but sent later.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/notification-gotify;

Also deploy the [Gotify server ↗️](https://github.com/gotify/server) and
optionally install a Gotify client on your mobile device.

Configuration
-------------

Follow the [Installation ↗️](https://gotify.net/docs/install) instructions
and the [First Login ↗️](https://gotify.net/docs/first-login) setup. Once
you have a user and account you can start creating apps. Each app is an
independent notification feed for a device or application.

![Create new app](notification-gotify.d/appsetup.avif)
 
On creation apps are assigned a *Token* for authentification, you will need
that in configuration.

Edit `global-config-overlay`, add `GotifyServer` with your server address
(just the address, no protocol - `https://` is assumed) and `GotifyToken`
with the *Token* from your configured app on the Gotify server. Then reload
the configuration.

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

For a custom service installing an additional certificate may be required.
You may want to install that certificate manually, after finding the
[certificate name from browser](../../CERTIFICATES.md).

Usage and invocation
--------------------

There's nothing special to do. Every script or function sending a notification
will now send it to your Gotify application feed.

But of course you can use the function to send notifications directly. Give
it a try:

    $SendGotify "Subject..." "Body...";

Alternatively this sends a notification with all available and configured
methods:

    $SendNotification "Subject..." "Body...";

To use the functions in your own scripts you have to declare them first.
Place this before you call them:

    :global SendGotify;
    :global SendNotification;

In case there is a situation when the queue needs to be purged there is a
function available:

    $PurgeGotifyQueue;

See also
--------

* [Certificate name from browser](../../CERTIFICATES.md)
* [Send notifications via e-mail](notification-email.md)
* [Send notifications via Matrix](notification-matrix.md)
* [Send notifications via Ntfy](notification-ntfy.md)
* [Send notifications via Telegram](notification-telegram.md)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
