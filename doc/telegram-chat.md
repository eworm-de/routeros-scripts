Chat with your router and send commands via Telegram bot
========================================================

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------

This script makes your device poll a Telegram bot for new messages. With
these messages you can send commands to your device and make it run them.
The resulting output is send back to you.

Requirements and installation
-----------------------------

Just install the script and the module for notifications via Telegram:

    $ScriptInstallUpdate telegram-chat,mod/notification-telegram;

Then create a schedule that runs the script periodically:

    /system/scheduler/add start-time=startup interval=30s name=telegram-chat on-event="/system/script/run telegram-chat;";

> ⚠️ **Warning**: Make sure to keep the interval in sync when installing
> on several devices. Differing polling intervals will result in missed
> messages.

Configuration
-------------

Make sure to configure
[notifications via telegram](mod/notification-telegram.md) first. The
additional configuration goes to `global-config-overlay`, these are the
parameters:

* `TelegramChatIdsTrusted`: an array with trusted chat ids or user names
* `TelegramChatGroups`: define the groups a device should belong to

Usage and invocation
--------------------

This script is capable of chatting with multiple devices. By default a
device is passive and not acting on messages. To activate it send a message
containing `! identity` (exclamation mark, optional space and system's
identity). To query all dynamic ip addresses form a device named "*MikroTik*"
send `! MikroTik`, followed by `/ip/address/print where dynamic;`.

![chat to specific device](telegram-chat.d/01-chat-specific.avif)

Devices can be grouped to chat with them simultaneously. The default group
"*all*" can be activated by sending `! @all`, which will make all devices
act on your commands.

![chat to all devices](telegram-chat.d/02-chat-all.avif)

Send a single exclamation mark or non-existent identity to make all
devices passive again.

Known limitations
-----------------

### Do not use numeric ids!

Numeric ids are valid within a session only. Usually you can use something
like this to print all ip addresses and remove the first one:

    /ip/address/print;
    /ip/address/remove 0;

This will fail when sent in separate messages. Instead you should use basic
scripting capabilities. Try to print what you want to act on...

    /ip/address/print where interface=eth;

... verify and finally remove it.

    /ip/address/remove [ find where interface=eth ];

### Sending commands to a group

Adding a bot to a group allows it to send messages to that group. To allow
it to receive messages you have to make it an admin of that group! It is
fine to deny all permissions, though.

See also
--------

* [Send notifications via Telegram](mod/notification-telegram.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
