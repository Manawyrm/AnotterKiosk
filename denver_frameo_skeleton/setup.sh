#!/bin/bash
set -x -e

apt update
# make sure we have all updates installed (from the -updates and -security repos)
APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confold" -f -y dist-upgrade

apt install -y polkitd locales zstd dhcpcd wpasupplicant
locale-gen en_US.UTF-8

useradd -U -m -s /bin/bash -u 1000 -G audio,video,users,input,adm,dialout,plugdev,render pi

# experimental Wayland support (Chromium running in x11 mode in Xwayland)
apt install -y --no-install-recommends cage seatd wlr-randr chromium xwayland

# remove stock WiFi config (AnotterKiosk ships its own)
rm /etc/network/interfaces.d/wlan0

# disable stock services
systemctl disable boot-config.service || true
systemctl disable ssh-host-keys.service || true
systemctl disable growroot.service || true

# eMMC can be writeable
rm -f /etc/udev/rules.d/60-emmc-readonly.rules

# disable password login for root
rm -f /etc/ssh/sshd_config.d/frame.conf

# remove root password
passwd -d root
