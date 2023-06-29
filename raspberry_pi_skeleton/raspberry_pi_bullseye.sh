#!/bin/bash

echo > /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bookworm main contrib non-free" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free" >> /etc/apt/sources.list

apt update
APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confold" -f -y dist-upgrade
