#!/bin/bash

set -x -e

RASPIOS_URL="$1"
RASPIOS_SHA256="$2"
IMAGE_SUFFIX="$3"

# *sigh*, some docker containers don't seem to have sbin in their PATH
export PATH=$PATH:/usr/sbin

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BUILD_DIR="${SCRIPT_DIR}/work/root/"

# cleanup any previous build attempts
umount -fl "${BUILD_DIR}" || true
losetup -D /dev/loop0 || true
rm -rf "${BUILD_DIR}" || true
mkdir -p "${BUILD_DIR}"

# delete any old image (comment this when testing locally)
rm raspios.img.xz || true

# download a modern RaspiOS build
if [ ! -f raspios.img.xz ]
then
	wget -nv -O raspios.img.xz "${RASPIOS_URL}"
	echo "${RASPIOS_SHA256} raspios.img.xz" | sha256sum --check --status
	if [ $? -ne 0 ]
	then
	    echo "downloaded raspios does not match checksum";
	    return -1;
	fi
fi

rm -f raspios.img
xz -kd raspios.img.xz

# Repartition image
mv raspios.img raspikiosk.img
truncate -s +3G raspikiosk.img
echo ", +" | sfdisk -N2 ./raspikiosk.img

# Setup loop device for Raspberry Pi image (with partition scanning)
sudo losetup -P /dev/loop0 raspikiosk.img

# Resize partition
sudo resize2fs /dev/loop0p2

# Manually set PARTUUID to 0x23421312
sudo fdisk /dev/loop0 <<EOF > /dev/null
p
x
i
0x23421312
r
p
w
EOF

# Mount partitions
sudo mount /dev/loop0p2 "${BUILD_DIR}"
sudo mount /dev/loop0p1 "${BUILD_DIR}/boot/firmware"

# Copy the (raspberry pi-specific) skeleton files
sudo rsync -a "${SCRIPT_DIR}/raspberry_pi_skeleton/." "${BUILD_DIR}" || true
sudo rsync -a "${SCRIPT_DIR}/kiosk_skeleton/." "${BUILD_DIR}/kiosk_skeleton" || true

# Use correct architecture specific (arm64/armhf) config.txt
sudo rm "${BUILD_DIR}/boot/firmware/config.txt"
sudo mv "${BUILD_DIR}/boot/firmware/config-${IMAGE_SUFFIX}.txt" "${BUILD_DIR}/boot/firmware/config.txt"

# Include git repo version info
echo -n "AnotterKiosk Raspberry Pi version: " > "${BUILD_DIR}/version-info"
git describe --abbrev=4 --dirty --always --tags >> "${BUILD_DIR}/version-info"

# Mount system partitions (from the build host)
sudo mount proc -t proc -o nosuid,noexec,nodev "${BUILD_DIR}/proc/"
sudo mount sys -t sysfs -o nosuid,noexec,nodev,ro "${BUILD_DIR}/sys/"
sudo mount devpts -t devtmpfs -o mode=0755,nosuid "${BUILD_DIR}/dev/"

# and then actually install everything.
sudo chroot "${BUILD_DIR}" /kiosk_skeleton/build.sh

sudo rm -r "${BUILD_DIR}/kiosk_skeleton"

cp "${BUILD_DIR}/version-info" version-info

# trim all filesystems
sudo fstrim -a

# fill unused space on /boot with 0x00 
# (FAT32, so zerofree doesn't work, we'll do it manually)
sudo dd if=/dev/zero of="${BUILD_DIR}/boot/firmware/zerofree" bs=1M || true
sudo rm "${BUILD_DIR}/boot/firmware/zerofree" || true

sudo umount -fl "${BUILD_DIR}/proc" || true
sudo umount -fl "${BUILD_DIR}/sys" || true
sudo umount -fl "${BUILD_DIR}/dev" || true

sudo umount "${BUILD_DIR}/proc" || true
sudo umount "${BUILD_DIR}/sys" || true
sudo umount "${BUILD_DIR}/dev" || true

sudo umount "${BUILD_DIR}/boot/firmware" || true
sudo umount "${BUILD_DIR}" || true

# set all empty blocks on ext4 to 0x00 (for better compression)
sudo zerofree /dev/loop0p2

sudo losetup -D /dev/loop0

tag=$(git describe --abbrev=4 --dirty --always --tags)
mv raspikiosk.img anotterkiosk-${tag}-${IMAGE_SUFFIX}.img
xz -T0 anotterkiosk-${tag}-${IMAGE_SUFFIX}.img
