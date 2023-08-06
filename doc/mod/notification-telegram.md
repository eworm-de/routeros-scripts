Send notifications via Telegram
===============================

[⬅️ Go back to main README](../../README.md)

> ℹ️️ **Info**: This module can not be used on its own but requires the base
> installation. See [main README](../../README.md) for details.

Description
-----------

This module adds support for sending notifications via
[Telegram](https://telegram.org/) via bot api. A queue is used to make sure
notifications are not lost on failure but sent later.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/notification-telegram;

Also install Telegram on at least one of your mobile and/or desktop devices
and create an account.

Configuration
-------------

Open Telegram, then start a chat with [BotFather](https://t.me/BotFather) and
create your own bot:

![create new bot](notification-telegram.d/newbot.avif)

Now open a chat with your bot and start it by clicking the `START` button.

Open just another chat with [GetIDs Bot](https://t.me/getidsbot), again start
with the `START` button. It will send you some information, including the
`id`, just below `You`.

Finally edit `global-config-overlay`, add `TelegramTokenId` with the token
from *BotFather* and `TelegramChatId` with your id from *GetIDs Bot*. Then
reload the configuration.

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

### Notifications to a group

Sending notifications to a group is possible as well. Add your bot and the
*GetIDs Bot* to a group, then use the group's id (which starts with a dash)
for `TelegramChatId`. Then remove *GetIDs Bot* from group.

Usage and invocation
--------------------

There's nothing special to do. Every script or function sending a notification
will now send it to your Telegram account.

But of course you can use the function to send notifications directly. Give
it a try:

    $SendTelegram "Subject..." "Body..."

Alternatively this sends a notification with all available and configured
methods:

    $SendNotification "Subject..." "Body..."

To use the functions in your own scripts you have to declare them first.
Place this before you call them:

    :global SendTelegram;
    :global SendNotification;

In case there is a situation when the queue needs to be purged there is a
function available:

    $PurgeTelegramQueue;

Tips & Tricks
-------------

### Set a profile photo

You can use a profile photo for your bot to make it recognizable. Open the
chat with [BotFather](https://t.me/BotFather) and set it there.

![set profile photo](notification-telegram.d/setuserpic.avif)

Have a look at my
[RouterOS-Scripts Logo Color Changer](https://git.eworm.de/cgit/routeros-scripts/plain/contrib/logo-color.html)
to create a colored version of this scripts' logo.

See also
--------

* [Chat with your router and send commands via Telegram bot](../telegram-chat.md)
* [Send notifications via e-mail](notification-email.md)
* [Send notifications via Matrix](notification-matrix.md)

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
