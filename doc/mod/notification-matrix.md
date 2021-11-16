Send notifications via Matrix
=============================

[◀ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds support for sending notifications via
[Matrix](https://matrix.org/) via client server api. A queue is used to
make sure notifications are not lost on failure but sent later.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/notification-matrix;

Also install a Matrix client on at least one of your mobile and/or desktop
devices and create an account.

Configuration
-------------

Edit `global-config-overlay`, add `MatrixHomeServer`, `MatrixAccessToken` and
`MatrixRoom`. Then reload the configuration.

Usage and invocation
--------------------

There's nothing special to do. Every script or function sending a notification
will now send it to your Matrix account.

See also
--------

* [Send notifications via Telegram](notification-telegram.md)

---
[◀ Go back to main README](../../README.md)  
[▲ Go back to top](#top)
