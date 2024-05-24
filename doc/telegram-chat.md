Chat with your router and send commands via Telegram bot
========================================================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

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

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Usage and invocation
--------------------

### Activating device(s)

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

### Reply to message

Let's assume you received a message from a device before, and want to send
a command to that device. No need to activate it, you can just reply to
that message.

![reply to message](telegram-chat.d/03-reply.avif)

Associated messages are cleared on device reboot.

### Ask for devices

Send a message with a single question mark (`?`) to query for devices
currenty online. The answer can be used for command via reply then.

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

What does work is using the persistent ids:

    /ip/address/print show-ids;

The output contains an id starting with asterisk that can be used:

    /ip/address/remove *E;

### Mind command runtime

The command is run in background while the script waits for it - about
20 seconds at maximum. A command exceeding that time continues to run in
background, but the output in the message is missing or truncated then.

If you still want a response you can work around this by making your code
send information on its own. Something like this should do the job:

    :global SendTelegram;
    :delay 30s;
    $SendTelegram "Command finished" "Your command finished...";

### Output size

Telegram messages have a limit of 4096 characters. If output is too large it
is truncated, and a warning is added to the message.

### Sending commands to a group

Adding a bot to a group allows it to send messages to that group. To allow
it to receive messages you have to make it an admin of that group! It is
fine to deny all permissions, though.

Also adding an admin to a group can cause the group id to change, so check
that if notifications break suddenly.

See also
--------

* [Send notifications via Telegram](mod/notification-telegram.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
