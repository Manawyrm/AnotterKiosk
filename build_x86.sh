#!/bin/bash

set -x -e

# *sigh*, some docker containers don't seem to have sbin in their PATH
export PATH=$PATH:/usr/sbin

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BUILD_DIR="${SCRIPT_DIR}/work/root/"

# cleanup any previous build attempts
umount -fl "${BUILD_DIR}" || true
rm -rf "${BUILD_DIR}" || true
mkdir -p "${BUILD_DIR}"
rm x86kiosk.img || true

truncate -s 10G x86kiosk.img

PARTLAYOUT=$(cat <<-END
label: gpt
label-id: 3BC7D7CD-4BF8-4E92-AAEB-2ACD5F8D05AA
device: x86kiosk.img
unit: sectors
first-lba: 34
last-lba: 20971486
sector-size: 512

x86kiosk.img1 : start=        2048, size=     2095105, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7, uuid=9C99F1BB-11A8-4BB5-82C2-555D7A38F85C, name="EFI system partition"
x86kiosk.img2 : start=     2099200, size=    18870272, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=93A9AB2C-BC29-4C6C-B6DD-1B4EDDED9A1E, name="Linux filesystem"
END
)
echo "${PARTLAYOUT}" | sfdisk x86kiosk.img

# Setup loop device for x86 image (with partition scanning)
ld=$(sudo losetup -P --show -f x86kiosk.img)

# Create filesystems
sudo mkfs.ext4 "${ld}p2"
sudo mkfs.fat -F 32 "${ld}p1"

# Mount partitions
sudo mount "${ld}p2" "${BUILD_DIR}"
sudo mkdir "${BUILD_DIR}/boot"
sudo mount "${ld}p1" "${BUILD_DIR}/boot"

# Debootstrap debian
sudo debootstrap --include=linux-image-amd64,grub-efi,sudo --arch amd64 trixie "${BUILD_DIR}" http://deb.debian.org/debian/

# Copy the skeleton files
sudo rsync -a "${SCRIPT_DIR}/x86_skeleton/." "${BUILD_DIR}"
sudo rsync -a "${SCRIPT_DIR}/kiosk_skeleton/." "${BUILD_DIR}/kiosk_skeleton"

# Create fstab
fat_uuid=$(lsblk -no UUID "${ld}p1")
ext_uuid=$(lsblk -no UUID "${ld}p2")

echo "UUID=${fat_uuid}  /boot           vfat    ro,defaults          0       2" | sudo tee "${BUILD_DIR}/etc/fstab"
echo "UUID=${ext_uuid}  /               ext4    ro,defaults,noatime  0       1" | sudo tee -a "${BUILD_DIR}/etc/fstab"

# Include git repo version info
echo -n "AnotterKiosk x86 version: " > "${BUILD_DIR}/version-info"
git describe --abbrev=4 --dirty --always --tags >> "${BUILD_DIR}/version-info"

# Mount system partitions (from the build host)
sudo mount proc -t proc -o nosuid,noexec,nodev "${BUILD_DIR}/proc/"
sudo mount sys -t sysfs -o nosuid,noexec,nodev,ro "${BUILD_DIR}/sys/"
sudo mount devpts -t devtmpfs -o mode=0755,nosuid "${BUILD_DIR}/dev/"

# and then actually install everything.
sudo chroot "${BUILD_DIR}" /setup.sh
sudo chroot "${BUILD_DIR}" /kiosk_skeleton/build.sh

sudo rm -r "${BUILD_DIR}/kiosk_skeleton"

cp "${BUILD_DIR}/version-info" version-info

# trim all filesystems
sudo fstrim -a

# fill unused space on /boot with 0x00 
# (FAT32, so zerofree doesn't work, we'll do it manually)
sudo dd if=/dev/zero of="${BUILD_DIR}/boot/zerofree" bs=1M || true
sudo rm "${BUILD_DIR}/boot/zerofree" || true

sudo umount -fl "${BUILD_DIR}/proc" || true
sudo umount -fl "${BUILD_DIR}/sys" || true
sudo umount -fl "${BUILD_DIR}/dev" || true

sudo umount "${BUILD_DIR}/proc" || true
sudo umount "${BUILD_DIR}/sys" || true
sudo umount "${BUILD_DIR}/dev" || true

sudo umount "${BUILD_DIR}/boot" || true
sudo umount "${BUILD_DIR}" || true

# set all empty blocks on ext4 to 0x00 (for better compression)
sudo zerofree "${ld}p2"

sudo losetup -D "${ld}"

tag=$(git describe --abbrev=4 --dirty --always --tags)
mv x86kiosk.img anotterkiosk-${tag}-x86.img
xz -T0 anotterkiosk-${tag}-x86.img