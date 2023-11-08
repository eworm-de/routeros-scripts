Send notifications via e-mail
=============================

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds support for sending notifications via e-mail. A queue is
used to make sure notifications are not lost on failure but sent later.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/notification-email;

Also you need a valid e-mail account with smtp login credentials.

Configuration
-------------

Set up your device's
[e-mail settings](https://wiki.mikrotik.com/wiki/Manual:Tools/email).
Also make sure the device has correct time configured, best is to set up
the ntp client.

Then edit `global-config-overlay`, add `EmailGeneralTo` with a valid
recipient address. Finally reload the configuration.

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

### Sending to several recipients

Sending notifications to several recipients is possible as well. Add
`EmailGeneralCc` on top, which can have a single mail address or a comma
separated list.

Usage and invocation
--------------------

There's nothing special to do. Every script or function sending a notification
will now send it to your e-mail account.

But of course you can use the function to send notifications directly. Give
it a try:

    $SendEMail "Subject..." "Body...";

Alternatively this sends a notification with all available and configured
methods:

    $SendNotification "Subject..." "Body...";

To use the functions in your own scripts you have to declare them first.
Place this before you call them:

    :global SendEMail;
    :global SendNotification;

In case there is a situation when the queue needs to be purged there is a
function available:

    $PurgeEMailQueue;

See also
--------

* [Send notifications via Matrix](notification-matrix.md)
* [Send notifications via Ntfy](notification-ntfy.md)
* [Send notifications via Telegram](notification-telegram.md)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
