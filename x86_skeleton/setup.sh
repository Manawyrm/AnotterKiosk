#!/bin/bash

echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list
apt update
apt install -y polkitd locales zstd dhcpcd wpa_supplicant
locale-gen en_US.UTF-8

apt install -y firmware-amd-graphics firmware-iwlwifi firmware-brcm80211 firmware-atheros firmware-misc-nonfree firmware-realtek

echo "grub-efi-amd64 grub2/force_efi_extra_removable boolean true" | debconf-set-selections
update-grub
grub-install --target=x86_64-efi --efi-directory=/boot --removable --bootloader-id=AnotterKiosk 

useradd -U -m -s /bin/bash -u 1000 -G audio,video,users,input,adm,dialout,plugdev,render pi

systemctl enable dhcpcd

rm /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 2001:4860:4860::8844" >> /etc/resolv.conf