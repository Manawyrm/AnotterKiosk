# AnotterKiosk

Another kiosk browser OS? Yes, this one is a little bit opinionated :)  

The author ran several similar setups in production for years and has seen a lot of problems and strange failure modes.  
This project aims to solve a lot of those (at least for the author), it might also be useful for others :)  

Key features:
- Images built via CI
- WiFi connection support
- Raspberry Pi (Arm64) compatibility
- USB flash drive, USB SSD, etc. compatible
- aarch64 mode for Raspberry Pis (_significant_ performance improvements over armv7/32bit ARM)
- Read-only filesystem handling (no more broken SD cards)
- Configurable cache clear functionality
- HTTP watchdog (website needs to send heartbeat messages via XHR/AJAX to localhost)
- Force specific resolution (1080p on 4k screens, broken EDID, etc.)
- Hard NTP handling (will wait for NTP at boot)
- SSH support
- VNC support
- SSH tunneling support (for remote-access without port-forwarding, etc.)

Planned features:
- PC (x86) compatibility
- Raspberry Pi PXE/network boot support
- Network connectivity watchdog (configurable ping, etc. timeout)
- Automatic reboot at specified time

Security considerations:
- Autossh does not check SSH host keys. This is okay-ish as long as the target server only allows tunneling, nothing else.
- nginx/PHP are allowed to use sudo/NOPASSWD (because it needs to query the VideoCore, manage service, etc.), more priviledge seperation would be nice
- due to the skeleton mechanism, the system has some ... creative permissions. some cleanup required.

Inspirations / Other Kiosk-OSes:
- https://github.com/jareware/chilipie-kiosk/
- https://github.com/guysoft/FullPageOS