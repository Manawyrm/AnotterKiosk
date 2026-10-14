#!/bin/bash

set -x -e

RK3126_URL="$1"
RK3126_SHA256="$2"
IMAGE_SUFFIX="$3"

# *sigh*, some docker containers don't seem to have sbin in their PATH
export PATH=$PATH:/usr/sbin

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BUILD_DIR="${SCRIPT_DIR}/work/root/"

# cleanup any previous build attempts
umount -fl "${BUILD_DIR}" || true
losetup -D /dev/loop3 || true
rm -rf "${BUILD_DIR}" || true
mkdir -p "${BUILD_DIR}"

# delete any old image (comment this when testing locally)
rm rk3126.img.xz || true

# download a modern RK3126 build
if [ ! -f rk3126.img.xz ]
then
	wget -nv -O rk3126.img.xz "${RK3126_URL}"
	echo "${RK3126_SHA256} rk3126.img.xz" | sha256sum --check --status
	if [ $? -ne 0 ]
	then
	    echo "downloaded raspios does not match checksum";
	    return -1;
	fi
fi

rm -f rk3126.img
xz -kd rk3126.img.xz

# Repartition image
mv rk3126.img raspikiosk.img
truncate -s +3G raspikiosk.img
echo ", +" | sfdisk -N2 ./raspikiosk.img

# Setup loop device for Raspberry Pi image (with partition scanning)
sudo losetup -P /dev/loop3 raspikiosk.img

# Resize partition
sudo resize2fs /dev/loop3p2

# Manually set PARTUUID to 0x23421312
sudo fdisk /dev/loop3 <<EOF > /dev/null
p
x
i
0x23421312
r
p
w
EOF

# Mount partitions
sudo mount /dev/loop3p2 "${BUILD_DIR}"
sudo mount /dev/loop3p1 "${BUILD_DIR}/boot/firmware"

# Copy the (denver frameo-specific) skeleton files
sudo rsync -a "${SCRIPT_DIR}/denver_frameo_skeleton/." "${BUILD_DIR}" || true
sudo rsync -a "${SCRIPT_DIR}/kiosk_skeleton/." "${BUILD_DIR}/kiosk_skeleton" || true

# Include git repo version info
echo -n "AnotterKiosk Denver Frameo version: " > "${BUILD_DIR}/version-info"
git describe --abbrev=4 --dirty --always --tags >> "${BUILD_DIR}/version-info"

# Mount system partitions (from the build host)
sudo mount proc -t proc -o nosuid,noexec,nodev "${BUILD_DIR}/proc/"
sudo mount sys -t sysfs -o nosuid,noexec,nodev,ro "${BUILD_DIR}/sys/"
sudo mount devpts -t devtmpfs -o mode=0755,nosuid "${BUILD_DIR}/dev/"

# and then actually install everything.
sudo chroot "${BUILD_DIR}" /setup.sh
sudo chroot "${BUILD_DIR}" /kiosk_skeleton/build.sh

# HACK:
# Chromium 146 removes support for OpenGL ES 2.0, which is the highest the RK3128 supports.
# Downgrade Chromium to 145 to still have GPU accelleration:
wget -P "${BUILD_DIR}" "https://snapshot.debian.org/archive/debian-security/20260306T064009Z/pool/updates/main/c/chromium/chromium_145.0.7632.159-1~deb13u1_armhf.deb"
wget -P "${BUILD_DIR}" "https://snapshot.debian.org/archive/debian-security/20260306T064009Z/pool/updates/main/c/chromium/chromium-common_145.0.7632.159-1~deb13u1_armhf.deb"
wget -P "${BUILD_DIR}" "https://snapshot.debian.org/archive/debian-security/20260306T064009Z/pool/updates/main/c/chromium/chromium-sandbox_145.0.7632.159-1~deb13u1_armhf.deb"
sha256sum -c "${BUILD_DIR}/chromium145.sha256"

sudo chroot "${BUILD_DIR}" /setup_post.sh

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
sudo zerofree /dev/loop3p2

sudo losetup -D /dev/loop3

tag=$(git describe --abbrev=4 --dirty --always --tags)
mv raspikiosk.img anotterkiosk-${tag}-${IMAGE_SUFFIX}.img
xz -T0 anotterkiosk-${tag}-${IMAGE_SUFFIX}.img
