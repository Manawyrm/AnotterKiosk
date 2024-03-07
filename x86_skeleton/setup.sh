#!/bin/bash

apt update
# make sure we have all updates installed (from the -updates and -security repos)
APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confold" -f -y dist-upgrade
APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt install -f -y -t bookworm-backports linux-image-amd64
# to remove old kernel versions
apt --purge autoremove
apt install -y polkitd locales zstd dhcpcd wpasupplicant xserver-xorg-video-nouveau
locale-gen en_US.UTF-8

apt install -y firmware-amd-graphics firmware-iwlwifi firmware-brcm80211 firmware-atheros firmware-misc-nonfree firmware-realtek firmware-ath9k-htc

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
