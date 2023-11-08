Send notifications via Ntfy
===========================

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
