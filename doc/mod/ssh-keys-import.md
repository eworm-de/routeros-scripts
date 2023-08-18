Import ssh keys for public key authentication
=============================================

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

    $SSHKeysImport "ssh-rsa ssh-rsa AAAAB3Nza...QYZk8= user" admin;

The third part of the key (`user` in this example) is inherited as
`key-owner` in RouterOS.

### Import several keys from file

The functions `$SSHKeysImportFile` can read an `authorized_keys`-style file
and import all the keys. The user given to the function can be overwritting
from comments in the file. Create a file `keys.pub` with this content:

```
ssh-rsa AAAAB3Nza...QYZk8= user@client
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
