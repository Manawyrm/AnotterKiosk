#!/bin/bash

# *sigh*, some docker containers don't seem to have sbin in their PATH
export PATH=$PATH:/usr/sbin

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BUILD_DIR="${SCRIPT_DIR}/work/root/"

umount -fl "${BUILD_DIR}" || true
losetup -D /dev/loop0 || true
rm -rf "${BUILD_DIR}" || true
mkdir -p "${BUILD_DIR}"

if [ ! -f raspios.img.xz ]
then
	wget -O raspios.img.xz "https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-05-03/2023-05-03-raspios-bullseye-arm64-lite.img.xz"
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
sudo rsync -a "${SCRIPT_DIR}/raspberry_pi_skeleton/." "${BUILD_DIR}"
sudo rsync -a "${SCRIPT_DIR}/kiosk_skeleton/." "${BUILD_DIR}/kiosk_skeleton"

# Mount system partitions (from the build host)
sudo mount proc -t proc -o nosuid,noexec,nodev "${BUILD_DIR}/proc/"
sudo mount sys -t sysfs -o nosuid,noexec,nodev,ro "${BUILD_DIR}/sys/"
sudo mount devpts -t devtmpfs -o mode=0755,nosuid "${BUILD_DIR}/dev/"

sudo chroot "${BUILD_DIR}" /raspberry_pi_bullseye.sh
sudo chroot "${BUILD_DIR}" /kiosk_skeleton/build.sh

sudo rm -r "${BUILD_DIR}/kiosk_skeleton"
sudo rm "${BUILD_DIR}/raspberry_pi_bullseye.sh"

sudo umount -fl "${BUILD_DIR}/proc"
sudo umount -fl "${BUILD_DIR}/sys"
sudo umount -fl "${BUILD_DIR}/dev"

sudo umount "${BUILD_DIR}/proc"
sudo umount "${BUILD_DIR}/sys"
sudo umount "${BUILD_DIR}/dev"

sudo umount "${BUILD_DIR}/boot"
sudo umount "${BUILD_DIR}"

sudo losetup -D /dev/loop0
