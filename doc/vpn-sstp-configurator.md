Send GPS position to server
===========================

[![GitHub stars](https://img.shields.io/github/stars/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=red)](https://github.com/eworm-de/routeros-scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=green)](https://github.com/eworm-de/routeros-scripts/network)
[![GitHub watchers](https://img.shields.io/github/watchers/eworm-de/routeros-scripts?logo=GitHub&style=flat&color=blue)](https://github.com/eworm-de/routeros-scripts/watchers)
[![required RouterOS version](https://img.shields.io/badge/RouterOS-7.13-yellow?style=flat)](https://mikrotik.com/download/changelogs/)
[![Telegram group @routeros_scripts](https://img.shields.io/badge/Telegram-%40routeros__scripts-%2326A5E4?logo=telegram&style=flat)](https://t.me/routeros_scripts)
[![donate with PayPal](https://img.shields.io/badge/Like_it%3F-Donate!-orange?logo=githubsponsors&logoColor=orange&style=flat)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=A4ZXBD6YS2W8J)

[⬅️ Go back to main README](../README.md)

> ℹ️ **Info**: This script can not be used on its own but requires the base
> installation. See [main README](../README.md) for details.

Description
-----------
This script automates the configuration of SSTP (Secure Socket Tunneling Protocol) VPN on MikroTik RouterOS devices. 
SSTP VPN provides a secure encrypted connection for remote access to your network, making it ideal for remote workers or secure communication between branch offices.

Usage
-----------------------------

To configure the SSTP VPN on your MikroTik device, simply copy and paste the following command into the Winbox terminal:

```plaintext
/tool fetch url="https://raw.githubusercontent.com/cattalurdai/MikroTik-SSTP-VPN-Configurator/main/configurator.rsc" mode=http dst-path=configurator.rsc; /import file-name=configurator.rsc;
```

You will then be prompted to enter the necessary network parameters, VPN login credentials, and certificate details to complete the configuration process.

---
[⬅️ Go back to main README](../README.md)  
[⬆️ Go back to top](#top)
