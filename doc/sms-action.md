Act on received SMS
===================

[◀ Go back to main README](../README.md)

Description
-----------

RouterOS can act on received SMS. Reboot the device from remote or do
whatever is required.

A broadband interface with SMS support is required.

Requirements and installation
-----------------------------

Just install the script:

    $ScriptInstallUpdate sms-action;

Configuration
-------------

The configuration goes to `global-config-overlay`, this is the only parameter:

* `SmsAction`: an array with pre-defined actions

Then enable SMS actions:

    / tool sms set allowed-number=+491234567890 receive-enabled=yes secret=s3cr3t;

Usage and invocation
--------------------

Send a SMS from allowed number to your device's phone number:

    :cmd s3cr3t script sms-action action=reboot;

The value given by "`action=`" is one of the pre-defined actions from
`SmsAction`.

See also
--------

* [Forward received SMS](sms-forward.md)

---
[◀ Go back to main README](../README.md)  
[▲ Go back to top](#top)
