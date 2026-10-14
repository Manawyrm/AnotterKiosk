#!/bin/bash

set -x -e

systemctl disable lightdm || true
systemctl enable kiosk-wayland || true

# HACK:
# Chromium 146 removes support for OpenGL ES 2.0, which is the highest the RK3128 supports.
# Downgrade Chromium to 145 to still have GPU accelleration:
sha256sum -c "${BUILD_DIR}/chromium145.sha256"
dpkg -i chromium*.deb
rm chromium*.deb
