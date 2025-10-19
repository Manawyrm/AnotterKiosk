#!/bin/bash
set -x -e

# This script is being run on the target debian platform
apt update

APT_LISTCHANGES_FRONTEND=none DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y --option=Dpkg::Options::=--force-confdef
DEBIAN_FRONTEND=noninteractive apt install -y wget curl fonts-noto-color-emoji lightdm openbox nginx php-fpm php-cli chromium autossh unclutter x11-xserver-utils xdotool htop nano openssh-server rsync x11vnc lm-sensors ntpsec-ntpdate scrot wireless-regdb fontconfig console-data ifupdown iproute2 wpasupplicant iw wireless-tools haveged rfkill

rsync -a --chown=root:root "/kiosk_skeleton/." "/"

# Raspberry Pi specific modifications
# raspberrypi-net-mods does things like copying /boot/firmware/wpa_supplicant.conf to the root FS
apt remove -y raspberrypi-net-mods || true
# userconf-pi prevents lightdm from starting unless the default "pi" user is changed
apt remove -y userconf-pi || true
# RF emissions are blocked by default
rfkill unblock wlan || true
# Chromium mods contain weird default configs like accessibility settings and some remote debugging API
apt remove -y rpi-chromium-mods || true
# ZRAM will cause high CPU load and slow the system down, we want neither ZRAM nor swap to SD
apt remove -y rpi-swap systemd-zram-generator || true
# Raspberry Pi OS ships with cloud-init, which seems like a bad idea for security
apt remove -y cloud-guest-utils cloud-init || true
# We really don't want to automount/touch any USB devices
apt remove -y udisks2 || true
# Raspbian ships network-manager, we want ifupdown
apt remove -y network-manager || true

# fix file system permissions
chown -hR 0:0 /etc/sudoers.d/
chown -hR www-data:www-data /var/www/html/

mkdir -p /home/pi/.config/chromium/
chown -hR 1000:1000 /home/pi/.config/chromium/
mkdir -p /home/pi/.cache
chown -hR 1000:1000 /home/pi/.cache
mkdir -p /home/pi/.pki/
chown -hR 1000:1000 /home/pi/.pki/
mkdir -p /home/pi/.ssh
chown -hR 1000:1000 /home/pi/.ssh
mkdir -p /root/.ssh

mkdir -p /var/lib/lightdm
mkdir -p /var/lib/dhcp
mkdir -p /var/lib/nginx
mkdir -p /var/lib/private

echo "tmpfs		/dev/shm	tmpfs	mode=0777	0	0" >> /etc/fstab
echo "tmpfs		/tmp		tmpfs	mode=1777	0	0" >> /etc/fstab
echo "tmpfs		/run		tmpfs	mode=0755,nosuid,nodev	0	0" >> /etc/fstab
echo "tmpfs		/var/log	tmpfs		defaults,noatime,nosuid,mode=0755,size=100m    0 0" >> /etc/fstab
echo "tmpfs		/var/lib/lightdm	tmpfs	defaults,noatime,nosuid,size=30m    0 0" >> /etc/fstab
echo "tmpfs		/var/lib/dhcp	tmpfs	defaults,noatime,nosuid,size=30m    0 0" >> /etc/fstab
echo "tmpfs		/var/lib/nginx	tmpfs	defaults,noatime,nosuid,size=30m    0 0" >> /etc/fstab
echo "tmpfs		/var/lib/private	tmpfs	defaults,noatime,nosuid,size=30m    0 0" >> /etc/fstab
echo "tmpfs		/home/pi/.cache tmpfs mode=0755,nosuid,nodev,uid=1000,gid=1000  0       0" >> /etc/fstab
echo "tmpfs		/home/pi/.config/chromium/ tmpfs mode=0755,nosuid,nodev,uid=1000,gid=1000  0       0" >> /etc/fstab
echo "tmpfs		/home/pi/.pki/ tmpfs mode=0755,nosuid,nodev,uid=1000,gid=1000  0       0" >> /etc/fstab
echo "tmpfs		/home/pi/.ssh/ tmpfs mode=0700,nosuid,nodev,uid=1000,gid=1000  0       0" >> /etc/fstab
echo "tmpfs		/root/.ssh/ tmpfs mode=0700,nosuid,nodev,uid=0,gid=0  0       0" >> /etc/fstab

# Create symlinks for configuration files which will later get created at runtime (in /tmp)
rm /etc/hosts || true
rm /etc/hostname || true
rm /etc/localtime || true
rm /etc/resolv.conf || true
mkdir -p /etc/wpa_supplicant/
ln -sf /tmp/hosts /etc/hosts
ln -sf /tmp/hostname /etc/hostname
ln -sf /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
ln -sf /tmp/asoundrc /home/pi/.asoundrc
ln -sf /tmp/localtime /etc/localtime
ln -sf /tmp/keyboard /etc/default/keyboard
ln -sf /tmp/resolv.conf /etc/resolv.conf

systemctl daemon-reload

# remove unneccessary clutter
systemctl disable apt-daily-upgrade.service || true
systemctl disable apt-daily-upgrade.timer || true
systemctl disable apt-daily.timer || true
systemctl disable avahi-daemon || true
systemctl disable bluetooth || true
systemctl disable dphys-swapfile || true
systemctl disable dpkg-db-backup.service || true
systemctl disable dpkg-db-backup.timer || true
systemctl disable e2scrub_all.timer || true
systemctl disable e2scrub_reap.service || true
systemctl disable fstrim.timer || true
systemctl disable logrotate.timer || true
systemctl disable man-db.timer || true
systemctl disable ModemManager || true
systemctl disable rpi-eeprom-update.service || true
systemctl disable rpi-resize.service || true
systemctl disable sshd-keygen.service || true
systemctl disable sshswitch.service || true
systemctl disable systemd-growfs-root.service || true
systemctl disable systemd-rfkill.service || true
systemctl disable systemd-rfkill.socket || true
systemctl disable systemd-timesyncd.service || true

systemctl enable kiosk-ssh-keys
systemctl enable kiosk-wifi
systemctl enable kiosk-autossh
systemctl enable kiosk-watchdog
systemctl enable kiosk-set-hostname
systemctl enable kiosk-locale
systemctl enable ntpdate
systemctl enable lightdm
systemctl enable nginx
systemctl enable ssh

# generate a version info/build info file
echo -n "Chromium version: " >> /version-info
dpkg --list | grep "ii  chromium " >> /version-info

echo -n "Linux kernel version: " >> /version-info
ls /lib/modules/  | sort -r | head -n 1 >> /version-info
echo >> /version-info
