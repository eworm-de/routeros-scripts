#!/bin/sh
#
# File: simple-routeros-update.sh
# Description: Upgrade to the last routeros stable version
# Author: Miquel Bonastre
# Date: 2025-03-11
#
# Inputs:
#   $1 - ssh user to use to connect to Mikrotik (usualy "admin")
#   $2 - Mikrotik address
#
# The address can be:
#  - Previously configured IP address
#  - Default address: 192.168.88.1
#  - Local link IPv6 address
#

if [ -z "$2" ]; then
  echo Missing parameters
  echo $0 user addr
  exit 1
fi

SSH="ssh -nq"
SCP="scp -q"

if ! $SSH -l "$1" "$2" ":put" \"Hello World\" \; ; then
  exit 1
fi

echo "Copy simple-routeros-update.rsc via scp:"
$SCP simple-routeros-update.rsc "$1@[$2]":

echo "Exec simple-routeros-update via ssh:"
$SSH -l "$1" "$2" "/import simple-routeros-update.rsc;"

echo "Force exit if router has restarted (execute again until last version installed)"
$SSH -l "$1" "$2" "/system/clock/print" || exit 1

echo "If you see the output of /system/clock/print means there are no more upgrades"

echo "End of simple-routeros-update"


# How to find router's local link IPv6 address:
#   ping -6 fe80::%n
#
# Where n is the number of the interface where the router can be found as reported by "ip link":
#
# Example:
# $ ip link
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
# 3: enx207bd2dc0ebe: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
#     link/ether 20:7b:d2:dc:0e:be brd ff:ff:ff:ff:ff:ff
#
# ping -6 'fe80::%9' -c 4
# PING fe80::%9(fe80::%enx00b56d00e148) 56 data bytes
# 64 bytes from fe80::ba69:f4ff:fe77:beef%enx00b56d00e148: icmp_seq=1 ttl=64 time=0.405 ms
# 64 bytes from fe80::ba69:f4ff:fe77:beef%enx00b56d00e148: icmp_seq=2 ttl=64 time=0.479 ms
# 64 bytes from fe80::ba69:f4ff:fe77:beef%enx00b56d00e148: icmp_seq=3 ttl=64 time=0.461 ms
# 64 bytes from fe80::ba69:f4ff:fe77:beef%enx00b56d00e148: icmp_seq=4 ttl=64 time=0.374 ms
# --- fe80::%9 ping statistics ---
# 4 packets transmitted, 4 received, 0% packet loss, time 3053ms
# rtt min/avg/max/mdev = 0.374/0.429/0.479/0.042 ms
#
# Temporal connection to Mikrotik via ssh:
#   ssh -l admin 'fe80::<found values>'
#   example: ssh -l admin 'fe80::ba69:f4ff:fe77:beef%enx00b56d00e148'
#
# Temporal connection via Winbox:
#   [fe80:....%n]
#   example: [fe80::ba69:f4ff:fe77:beef%9]
#
