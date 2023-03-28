Forward received SMS
====================

[⬅️ Go back to main README](../README.md)

![required RouterOS version](https://img.shields.io/badge/RouterOS-7.9beta4-yellow?style=flat)

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
  For `match` and `allowed-number` regular expressions are supported.

Notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md) and/or
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
