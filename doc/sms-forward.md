Forward received SMS
====================

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

RouterOS can receive SMS. This script forwards SMS as notification.

A broadband interface with SMS support is required.

### Sample notification

![sms-forward notification](sms-forward.d/notification.avif)

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate sms-forward;

... and add a scheduler to run it periodically:

    /system/scheduler/add interval=2m name=sms-forward on-event="/system/script/run sms-forward;" start-time=startup;

Configuration
-------------

You have to enable receiving of SMS:

    /tool/sms/set receive-enabled=yes;

The configuration goes to `global-config-overlay`, this is the only parameter:

* `SmsForwardHooks`: an array with pre-defined hooks, where each hook consists
  of `match` (which is matched against the received message), `allowed-number`
  (which is matched against the sending phone number or name) and `command`.
  For `match` and `allowed-number` regular expressions are supported. Actual
  phone number (`$Phone`) and message (`$Message`) are available for the hook.

> ℹ️ **Info**: Copy relevant configuration from
> [`global-config`](../global-config.rsc) (the one without `-overlay`) to
> your local `global-config-overlay` and modify it to your specific needs.

Notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md),
[ntfy](mod/notification-ntfy.md) and/or
[telegram](mod/notification-telegram.md).

Tips & Tricks
-------------

### Take care of harmful commands!

It is easy to fake the sending phone number! So make sure you do not rely on
that number for potentially harmful commands. Add a shared secret to match
into the text instead, for example: `reboot-53cr3t-5tr1n9` instead of just
`reboot`.

### Order new volume

Most broadband providers include a volume limit for their data plans. The
hook functionality can be used to order new volume automatically.

Let's assume an imaginary provider **ABC** sends a message when the available
volume is about to deplete. The message is sent from `ABC` and the text
contains the string `80%`. New volume can be ordered by sending a SMS back to
the phone number `1234` with the text `data-plan`.

    :global SmsForwardHooks {
      { match="80%";
        allowed-number="ABC";
        command="/tool/sms/send lte1 phone-number=1234 message=\"data-plan\";" };
    };

Adjust the values to your own needs.

See also
--------

* [Act on received SMS](sms-action.md)

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
