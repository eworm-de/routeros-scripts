Send notifications via e-mail
=============================

[◀ Go back to main README](../../README.md)

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

### Sending to several recipients

Sending notifications to several recipients is possible as well. Add
`EmailGeneralCc` on top, which can have a single mail address or a comma
separated list.

Usage and invocation
--------------------

There's nothing special to do. Every script or function sending a notification
will now send it to your e-mail account.

But of course you can send notifications directly or use a function in your
own scripts. Give it a try:

    $SendEMail "Subject..." "Body..."

Alternatively this sends a notification with all available and configured
methods:

    $SendNotification "Subject..." "Body..."

See also
--------

* [Send notifications via Matrix](notification-matrix.md)
* [Send notifications via Telegram](notification-telegram.md)

---
[◀ Go back to main README](../../README.md)  
[▲ Go back to top](#top)
