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
devices. As there is no privilege separation you should create a dedicated
notification account, in addition to your general user account.

Configuration
-------------

Edit `global-config-overlay`, add `MatrixHomeServer`, `MatrixAccessToken` and
`MatrixRoom` - see below on hints how to retrieve this information. Then
reload the configuration.

### Home server

Matrix user accounts are identified by a unique user id in the form of
`@localpart:domain`. The `domain` part is not necessarily your home server
address, you have to resolve it with the procedure described in the
[Matrix specification](https://spec.matrix.org/latest/client-server-api/#server-discovery).

Your best bet is to query the server at `domain` with the
[well-known uri](https://spec.matrix.org/latest/client-server-api/#well-known-uri).
For "*matrix.org*" this query is:

    / tool fetch "https://matrix.org/.well-known/matrix/client" output=user;

![home server](notification-matrix.d/01-home-server.avif)

So the home server for "*matrix.org*" is "*matrix-client.matrix.org*".
Please strip the protocol ("*https://*") for `MatrixHomeServer` if given.

### Access token

After discovering the correct home server an access token has to be created.
For this the login credentials (username and password) of the notification
account must be sent to the home server via
[client server api](https://matrix.org/docs/guides/client-server-api#login).

We use the home server discovered above, "*matrix-client.matrix.org*".
The user is "*example*" and password is "*v3ry-s3cr3t*".

    / tool fetch "https://matrix-client.matrix.org/_matrix/client/r0/login" http-method=post http-data="{\"type\":\"m.login.password\", \"user\":\"example\", \"password\":\"v3ry-s3cr3t\"}" output=user;

![access token](notification-matrix.d/02-access-token.avif)

The server replied with a JSON object containing the `access_token`, use that
for `MatrixAccessToken`.

### Room

Every Matix chat is a room, so we have to create one. Do so with your general
user, this makes sure your general user is the room owner. Then join the room
and invite the notification user by its user id "*@example:matrix.org*". Look
up the room id within the Matrix client, it should read like
"*!WUcxpSjKyxSGelouhA:matrix.org*". Use that for `MatrixRoom`.

Finally join the notification user to the room by accepting the invite. Again,
this can be done with 
[client server api](https://matrix.org/docs/guides/client-server-api#joining-a-room-via-an-invite).
Make sure to replace room id ("*!*" is escaped with "*%21*") and access token
with your data.

    / tool fetch "https://matrix-client.matrix.org/_matrix/client/r0/rooms/%21WUcxpSjKyxSGelouhA:matrix.org/join?access_token=yt_ZXdvcm0tdGVzdA_NNqUyvKHRhBLZmnzVVSK_0xu6yN" http-method=post http-data="" output=user;

![join room](notification-matrix.d/03-join-room.avif)

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
