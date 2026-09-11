Send notifications via Signalgrid
=================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.22-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds support for sending notifications via
[Signalgrid ↗️](https://signalgrid.co/). A queue is used to make sure
notifications are not lost on failure but sent later.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/notification-signalgrid;

A Signalgrid account, client key and channel are required.

Configuration
-------------

Configure `SignalgridClientKey` and `SignalgridChannel` with the client key
and channel from your Signalgrid account.

`SignalgridCritical` controls whether notifications are sent as critical by
default and defaults to `false`.

Edit `global-config-overlay`, add the required settings and reload the
configuration:

    :global SignalgridClientKey "your-client-key";
    :global SignalgridChannel "your-channel";
    :global SignalgridCritical false;

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Usage and invocation
--------------------

There's nothing special to do. Every script or function sending a notification
will now send it via Signalgrid.

But of course you can use the function to send notifications directly. Give
it a try:

    $SendSignalgrid "Subject..." "Body...";

Severity and critical delivery can optionally be specified:

    $SendSignalgrid "Subject..." "Body..." "warning" false;

For full control the array-based function accepts Signalgrid fields directly:

    $SendSignalgrid2 ({
      title="RouterOS alert";
      body="Something requires attention.";
      severity="critical";
      critical=true;
    });

Alternatively this sends a notification with all available and configured
methods:

    $SendNotification "Subject..." "Body...";

To use the functions in your own scripts you have to declare them first.
Place this before you call them:

    :global SendSignalgrid;
    :global SendSignalgrid2;
    :global SendNotification;

In case there is a situation when the queue needs to be purged there is a
function available:

    $PurgeSignalgridQueue;

See also
--------

* [Signalgrid documentation ↗️](https://docs.signalgrid.co/)
* [Send notifications via e-mail](notification-email.md)
* [Send notifications via Gotify](notification-gotify.md)
* [Send notifications via Matrix](notification-matrix.md)
* [Send notifications via Ntfy](notification-ntfy.md)
* [Send notifications via Telegram](notification-telegram.md)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
