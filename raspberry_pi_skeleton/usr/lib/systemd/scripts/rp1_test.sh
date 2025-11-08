#!/bin/bash

# Choose an appropriate "Primary GPU" for Xorg
# This should normally be vc4 (not v3d) but when some
# other display is enabled on Pi5, it should match that.

IDENTIFIER=vc4
MATCHDRIVER=vc4

if raspi-config nonint is_pifive; then
  if ls /dev/dri/by-path/ | grep -q '\(vec\|dsi\|dpi\)-card' ; then
    IDENTIFIER=rp1
    MATCHDRIVER='rp1-vec|rp1-dsi|rp1-dpi'
  fi
fi

sed -e "s/XXX/${IDENTIFIER}/" << EOF | sed -e "s/YYY/${MATCHDRIVER}/" > /tmp/99-v3d.conf
Section "OutputClass"
  Identifier "XXX"
  MatchDriver "YYY"
  Driver "modesetting"
  Option "PrimaryGPU" "true"
EndSection
EOF

