#!/bin/bash

echo > /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bookworm main contrib non-free" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free" >> /etc/apt/sources.list

apt update
APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confold" -f -y dist-upgrade

# This step is a bit risky, as the current kernel in https://github.com/raspberrypi/rpi-firmware might
# be less tested as the currently shipping kernel in the Raspberry Pi images.
# apt install -y rpi-update
# SKIP_CHECK_PARTITION=1 SKIP_WARNING=1 rpi-update