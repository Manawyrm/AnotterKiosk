#!/bin/bash

# Modified version of gldriver-test script for read-only root FS.

# Glamor should not run on platforms prior to Pi 4.

if ! raspi-config nonint gpu_has_mmu ; then
	if ! [ -e /kiosk-tmp/20-noglamor.conf ] ; then
		cat > /kiosk-tmp/20-noglamor.conf << EOF
Section "Device"
	Identifier "kms"
	Driver "modesetting"
	Option "AccelMethod" "msdri3"
	Option "UseGammaLUT" "off"
EndSection
EOF
	fi
else
	if [ -e /kiosk-tmp/20-noglamor.conf ] ; then
		rm /kiosk-tmp/20-noglamor.conf
	fi
fi
