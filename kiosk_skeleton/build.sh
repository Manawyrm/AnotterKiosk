#!/bin/bash
# This script is being run on the target debian platform

apt update
APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y
DEBIAN_FRONTEND=noninteractive apt install -y lightdm openbox nginx php-fpm php-cli chromium autossh unclutter x11-xserver-utils xdotool htop nano openssh-server rsync x11vnc lm-sensors ntpdate scrot

rsync -a --chown=root:root "/kiosk_skeleton/." "/"
chown -hR pi:pi /home/pi

# Raspberry Pi specific modifications
# raspberrypi-net-mods does things like copying /boot/wpa_supplicant.conf to the root FS
apt remove -y raspberrypi-net-mods || true
# userconf-pi prevents lightdm from starting unless the default "pi" user is changed
apt remove -y userconf-pi || true
# RF emissions are blocked by default
rfkill unblock wlan || true

# fix file system permissions
chown -hR 0:0 /etc/sudoers.d/
chown -hR www-data:www-data /var/www/html/

mkdir -p /home/pi/.config/chromium/
chown -hR 1000:1000 /home/pi/.config/chromium/

mkdir -p /home/pi/.pki/
chown -hR 1000:1000 /home/pi/.pki/

# FIXME: readonly in /etc/fstab
echo "tmpfs		/dev/shm	tmpfs	mode=0777	0	0" >> /etc/fstab
echo "tmpfs		/tmp		tmpfs	mode=1777	0	0" >> /etc/fstab
echo "tmpfs		/run		tmpfs	mode=0755,nosuid,nodev	0	0" >> /etc/fstab
echo "tmpfs		/var/log	tmpfs		defaults,noatime,nosuid,mode=0755,size=100m    0 0" >> /etc/fstab
echo "tmpfs		/var/lib/lightdm	tmpfs	defaults,noatime,nosuid,size=30m    0 0" >> /etc/fstab
echo "tmpfs		/var/lib/dhcpcd	tmpfs	defaults,noatime,nosuid,size=30m    0 0" >> /etc/fstab
echo "tmpfs		/home/pi/.cache tmpfs mode=0755,nosuid,nodev,uid=1000,gid=1000  0       0" >> /etc/fstab
echo "tmpfs		/home/pi/.config/chromium/ tmpfs mode=0755,nosuid,nodev,uid=1000,gid=1000  0       0" >> /etc/fstab
echo "tmpfs		/home/pi/.pki/ tmpfs mode=0755,nosuid,nodev,uid=1000,gid=1000  0       0" >> /etc/fstab

# Create symlinks for configuration files which will later get created at runtime (in /tmp)
rm /etc/hosts
rm /etc/hostname
mkdir -p /etc/wpa_supplicant/
ln -sf /tmp/hosts /etc/hosts
ln -sf /tmp/hostname /etc/hostname
ln -sf /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

systemctl daemon-reload

# remove unneccessary clutter
systemctl disable dphys-swapfile
systemctl disable ModemManager
systemctl disable avahi-daemon
systemctl disable bluetooth

systemctl enable kiosk-wifi
systemctl enable kiosk-autossh
systemctl enable kiosk-watchdog
systemctl enable kiosk-set-hostname
systemctl enable ntpdate
systemctl enable lightdm
systemctl enable nginx

# generate a version info/build info file
echo -n "Chromium version: " >> /version-info
dpkg --list | grep "ii  chromium " >> /version-info

echo -n "Linux kernel version: " >> /version-info
ls /lib/modules/ >> /version-info
echo >> /version-info
