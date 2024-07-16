Import ssh keys for public key authentication
=============================================

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

RouterOS supports ssh login with public key authentication. The functions
in this module help importing the keys.

Requirements and installation
-----------------------------

Just install the module:

    $ScriptInstallUpdate mod/ssh-keys-import;

Usage and invocation
--------------------

### Import single key from terminal

Call the function `$SSHKeysImport` with key and user as parameter to
import that key:

    $SSHKeysImport "ssh-ed25519 AAAAC3Nza...ZVugJT user" admin;
    $SSHKeysImport "ssh-rsa AAAAB3Nza...QYZk8= user" admin;

The third part of the key (`user` in this example) is inherited as
`key-owner` in RouterOS. Also the `MD5` fingerprint is recorded, this helps
to audit and verify the available keys.

> ℹ️️ **Info**: Use `ssh-keygen` to show a fingerprint of an existing public
> key file: `ssh-keygen -l -E md5 -f ~/.ssh/id_ed25519.pub`

### Import several keys from file

The functions `$SSHKeysImportFile` can read an `authorized_keys`-style file
and import all the keys. The user given to the function can be overwritting
from comments in the file. Create a file `keys.pub` with this content:

```
ssh-ed25519 AAAAC3Nza...3OcN8A user@client
ssh-rsa AAAAB3Nza...ozyts= worker@station
# user=example
ssh-rsa AAAAB3Nza...GXQVk= person@host
```

Then import it with:

    $SSHKeysImportFile keys.pub admin;

This will import the first two keys for user `admin` (as given to function)
and the third one for user `example` (as defined in comment).

---
[⬅️ Go back to main README](../../README.md)  
[⬆️ Go back to top](#top)
