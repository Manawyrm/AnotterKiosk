#!/bin/bash

set -x -e

# *sigh*, some docker containers don't seem to have sbin in their PATH
export PATH=$PATH:/usr/sbin

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BUILD_DIR="${SCRIPT_DIR}/work/root/"

# cleanup any previous build attempts
umount -fl "${BUILD_DIR}" || true
losetup -D /dev/loop0 || true
rm -rf "${BUILD_DIR}" || true
mkdir -p "${BUILD_DIR}"

# download a modern RaspiOS build
if [ ! -f raspios.img.xz ]
then
	wget -nv -O raspios.img.xz "https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-05-03/2023-05-03-raspios-bullseye-arm64-lite.img.xz"
	echo "bf982e56b0374712d93e185780d121e3f5c3d5e33052a95f72f9aed468d58fa7 raspios.img.xz" | sha256sum --check --status
	if [ $? -ne 0 ]
	then
	    echo "downloaded raspios does not match checksum";
	    return -1;
	fi
fi

rm -f raspios.img
xz -kd raspios.img.xz

# Repartition image
export LIBGUESTFS_BACKEND_SETTINGS=force_tcg
truncate -r raspios.img raspikiosk.img
truncate -s +3G raspikiosk.img

virt-resize --expand /dev/sda2 raspios.img raspikiosk.img
rm -f raspios.img

# Setup loop device for Raspberry Pi image (with partition scanning)
sudo losetup -P /dev/loop0 raspikiosk.img

# Mount partitions
sudo mount /dev/loop0p2 "${BUILD_DIR}"
sudo mount /dev/loop0p1 "${BUILD_DIR}/boot"

# Copy the (raspberry pi-specific) skeleton files
sudo rsync -a "${SCRIPT_DIR}/raspberry_pi_skeleton/." "${BUILD_DIR}" || true
sudo rsync -a "${SCRIPT_DIR}/kiosk_skeleton/." "${BUILD_DIR}/kiosk_skeleton" || true

# Make fstab read-only
sudo sed -i 's/vfat    defaults/vfat    ro,defaults/g' "${BUILD_DIR}/etc/fstab"
sudo sed -i 's/ext4    defaults/ext4    ro,defaults/g' "${BUILD_DIR}/etc/fstab"

# Include git repo version info
echo -n "AnotterKiosk Raspberry Pi version: " > "${BUILD_DIR}/version-info"
git describe --abbrev=4 --dirty --always --tags >> "${BUILD_DIR}/version-info"

# Mount system partitions (from the build host)
sudo mount proc -t proc -o nosuid,noexec,nodev "${BUILD_DIR}/proc/"
sudo mount sys -t sysfs -o nosuid,noexec,nodev,ro "${BUILD_DIR}/sys/"
sudo mount devpts -t devtmpfs -o mode=0755,nosuid "${BUILD_DIR}/dev/"

# Raspbian currently ships only Debian 11. Let's upgrade to 12.
sudo chroot "${BUILD_DIR}" /raspberry_pi_bullseye.sh

# and then actually install everything.
sudo chroot "${BUILD_DIR}" /kiosk_skeleton/build.sh

sudo rm -r "${BUILD_DIR}/kiosk_skeleton"
sudo rm "${BUILD_DIR}/raspberry_pi_bullseye.sh"

cp "${BUILD_DIR}/version-info" version-info

sudo umount -fl "${BUILD_DIR}/proc" || true
sudo umount -fl "${BUILD_DIR}/sys" || true
sudo umount -fl "${BUILD_DIR}/dev" || true

sudo umount "${BUILD_DIR}/proc" || true
sudo umount "${BUILD_DIR}/sys" || true
sudo umount "${BUILD_DIR}/dev" || true

sudo umount "${BUILD_DIR}/boot" || true
sudo umount "${BUILD_DIR}" || true

sudo losetup -D /dev/loop0

tag=$(git describe --abbrev=4 --dirty --always --tags)
mv raspikiosk.img anotterkiosk-${tag}-arm64-raspberrypi.img
pigz -4 anotterkiosk-${tag}-arm64-raspberrypi.img