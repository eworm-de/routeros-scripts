Debug output and logs
=====================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.15-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](README.md)

Sometimes scripts do not behave as expected. In these cases debug output
or logs can help.

## Debug output

Run this command in a terminal:

    :set PrintDebug true;

You will then see debug output when running the script from terminal.

To revert to default output run:

    :set PrintDebug false;

### Debug output for specific script

Even having debug output for a specific script or function only (or a
set of) is possible. To enable debug output for `telegram-chat` run:

    :set ($PrintDebugOverride->"telegram-chat") true;

## Debug logs

The debug info can go to system log. To make it show up in `memory` run:

    /system/logging/add topics=script,debug action=memory;

Other actions (`disk`, `email`, `remote` or `support`) can be used as
well. I do not recommend using `echo` - use [debug output](#debug-output)
instead.

Disable or remove that setting to restore regular logging.

## Verbose output

Specific scripts can generate huge amount of output. These do use a function
`$LogPrintVerbose`, which is declared, but has no code, intentionally.

If you *really* want that output set the function to be the same as
`$LogPrint`:

    :set LogPrintVerbose $LogPrint;

To revert that change just run:

    :set LogPrintVerbose;

---
[⬅️ Go back to main README](README.md)  
[⬆️ Go back to top](#top)
