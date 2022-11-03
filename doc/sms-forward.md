Forward received SMS
====================

[◀ Go back to main README](../README.md)

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

Notification settings are required for
[e-mail](mod/notification-email.md),
[matrix](mod/notification-matrix.md) and/or
[telegram](mod/notification-telegram.md).
Also you have to enable receiving of SMS:

    /tool/sms/set receive-enabled=yes;

The configuration goes to `global-config-overlay`, this is the only parameter:

* `SmsForwardHooks`: an array with pre-defined actions in form where the key of the array is the regular expression to match the SMS text and the value is the action to execute:

    ```
    :global SmsForwardHooks {
        { match="command";
        allowed-number="1234";
        command=":put "command executed"" };
    # add more here...
    };
    ```

    in this example the command `:put "command executed"` will be executed
    when a SMS with text starting with `command` is received from number `1234`.

    Useful use case is to send an SMS to order an additional internet package when the current one is about to deplete, and the automatic SMS is sent from the provider with the text that 80%, 100% of the package are used. Then, an automated SMS can be sent to a provider back to order a new package automatically.
    For example, for the [KPN](https://kpn.com/) provider, the SMS text is `NL2000 AAN` sent to number `1266` to order an additional 2GB package.
    Then, the following configuration can be used:

    ```
    :global SmsForwardHooks {
        { match="80%";
        allowed-number="KPN";
        command="/tool/sms/send lte1 phone-number=1266 message=\"NL2000 AAN\";" };
    };
    ```
    This reads as: when the SMS with text `80%` is received from number `KPN`, the SMS with text `NL2000 AAN` is sent to the provider.
    If you use unlimited plan, this is exactly what you need to do to order a new package automatically.

See also
--------

* [Act on received SMS](sms-action.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
