Send notifications via Matrix
=============================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.14-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../../README.md)

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
devices. Create and setup an account there, we will reference that as
"*general account*" later.

Configuration
-------------

Edit `global-config-overlay`, add `MatrixHomeServer`, `MatrixAccessToken` and
`MatrixRoom` - see below on hints how to retrieve this information. Then
reload the configuration.

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

The Matrix server is connected via encrypted https, and certificate
verification is applied. So make sure you have the certificate chain for
your server in device's certificate store.

### From other device

If you have setup your Matrix *notification account* before just reuse that.
Copy the relevant configuration to the device to be configured.

### Setup new account

As there is no privilege separation you should create a dedicated account
for use with these scripts, in addition to your *general account*.
We will reference that as "*notification account*" in the following steps.

#### Authenticate

Matrix user accounts are identified by a unique user id in the form of
`@localpart:domain`. Use that and your password to generate an access token
and write first part of the configuration:

    $SetupMatrixAuthenticate "@example:matrix.org" "v3ry-s3cr3t";

![authenticate](notification-matrix.d/01-authenticate.avif)

The configuration is written to a new configuration snippet
`global-config-overlay.d/mod/notification-matrix`.

#### Join Room

Every Matix chat is a room, so we have to create one. Do that with your
*general account*, this makes sure your *general account* is the room owner.
Then join the room and invite the *notification account* by its user id
"*@example:matrix.org*".
Look up the *room id* within the Matrix client, it should read like
"*!WUcxpSjKyxSGelouhA:matrix.org*" (starting with an exclamation mark and
ending with the domain).

Finally make the *notification account* join into the room by accepting
the invite.

    $SetupMatrixJoinRoom "!WUcxpSjKyxSGelouhA:matrix.org";

![join room](notification-matrix.d/02-join-room.avif)

The configuration is appended to the configuration snippet
`global-config-overlay.d/mod/notification-matrix`.

Usage and invocation
--------------------

There's nothing special to do. Every script or function sending a notification
will now send it to your Matrix account.

But of course you can use the function to send notifications directly. Give
it a try:

    $SendMatrix "Subject..." "Body...";

Alternatively this sends a notification with all available and configured
methods:

    $SendNotification "Subject..." "Body...";

To use the functions in your own scripts you have to declare them first.
Place this before you call them:

    :global SendMatrix;
    :global SendNotification;

In case there is a situation when the queue needs to be purged there is a
function available:

    $PurgeMatrixQueue;

See also
--------

* [Send notifications via e-mail](notification-email.md)
* [Send notifications via Ntfy](notification-ntfy.md)
* [Send notifications via Telegram](notification-telegram.md)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
