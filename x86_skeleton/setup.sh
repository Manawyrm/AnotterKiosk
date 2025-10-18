#!/bin/bash
set -x -e

apt update
# make sure we have all updates installed (from the -updates and -security repos)
APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confold" -f -y dist-upgrade

# install backports kernel (not needed on Debian 13/trixie right now)
#APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt install -f -y -t  trixie-backports linux-image-amd64

# to remove old kernel versions
apt --purge autoremove

apt install -y polkitd locales zstd dhcpcd wpasupplicant xserver-xorg-video-nouveau
locale-gen en_US.UTF-8

apt install -y firmware-amd-graphics firmware-iwlwifi firmware-brcm80211 firmware-atheros firmware-misc-nonfree firmware-realtek firmware-ath9k-htc

echo "grub-efi-amd64 grub2/force_efi_extra_removable boolean true" | debconf-set-selections
update-grub
grub-install --target=x86_64-efi --efi-directory=/boot/firmware --removable --bootloader-id=AnotterKiosk 

useradd -U -m -s /bin/bash -u 1000 -G audio,video,users,input,adm,dialout,plugdev,render pi
