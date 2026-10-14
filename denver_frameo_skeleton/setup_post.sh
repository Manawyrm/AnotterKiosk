#!/bin/bash

set -x -e

systemctl disable lightdm || true
systemctl enable kiosk-wayland || true

# HACK:
# Chromium 146 removes support for OpenGL ES 2.0, which is the highest the RK3128 supports.
# Downgrade Chromium to 145 to still have GPU accelleration:
wget "https://snapshot.debian.org/archive/debian-security/20260306T064009Z/pool/updates/main/c/chromium/chromium_145.0.7632.159-1~deb13u1_armhf.deb"
wget "https://snapshot.debian.org/archive/debian-security/20260306T064009Z/pool/updates/main/c/chromium/chromium-common_145.0.7632.159-1~deb13u1_armhf.deb"
wget "https://snapshot.debian.org/archive/debian-security/20260306T064009Z/pool/updates/main/c/chromium/chromium-sandbox_145.0.7632.159-1~deb13u1_armhf.deb"
sha256sum -c chromium145.sha256
dpkg -i chromium*.deb
rm chromium*.deb
rm chromium145.sha256
