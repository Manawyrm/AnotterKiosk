AnotterKiosk
=============================

<img src="https://screenshot.tbspace.de/zachejgwlkq.jpg" width="45%"> <img src="https://screenshot.tbspace.de/kuhmlynagbw.jpg" width="45%">
<img src="https://screenshot.tbspace.de/tdouafprbqk.jpg" width="45%"> <img src="https://screenshot.tbspace.de/rmhezfgucdj.jpg" width="45%">

## Overview
Another kiosk browser OS? Yes, this one is a little bit opinionated :grin:  

This project is a Debian Linux-based OS for computers, either PCs or Raspberry Pi's and has only one job:  
| :computer:  Display a web page in full screen very reliably and securely   |
|----------------------------------------------|

The author of this project ran several similar setups in production for years and has seen a lot of problems and strange failure modes.  
This project aims to solve a lot of those (at least for the author), it might also be useful for others :)  

Other similar projects:
- will run the computer in 32bit mode (making them very slow/laggy)
- write to the storage device (killing it in the long run, causing bad reliability)
- have insecure configurations (like open ports, network access or unsafe UI features)
- are not built via CI (instead have people manually building images)
- are missing watchdog functionality (can hang on browser error pages forever)

## Key features
- [Images built via CI](https://github.com/Manawyrm/AnotterKiosk/blob/main/.github/workflows/main.yml)
- WiFi & Ethernet connection support
- Raspberry Pi & PC (64-bit) compatibility
- [USB flash drive, USB SSD, etc. compatible](#how-to-use)
- aarch64 images for Raspberry Pis (_significant_ performance improvements over armv7/32bit ARM)
- 100% read-only filesystem (no more broken SD cards)
- Browser cache can be cleared at configurable intervals
- [HTTP watchdog (website needs to send heartbeat messages via XHR/AJAX to localhost)](#http-watchdog-functionality)
- Force specific resolution (1080p on 4k screens, broken EDID, etc.)
- Hard NTP handling (will wait for NTP at boot)
- SSH support
- VNC support
- SSH tunneling support (for remote-access without port-forwarding, on DS-Lite/cellular connections, etc.)

## Supported platforms
- Raspberry Pi 3, 4, 5, Zero 2 (W)
- PCs with UEFI (Intel, AMD or Nvidia GPUs)

**not recommended, but working**
- Raspberry Pi 1, 2, Zero (W) (very slow, 32bit only, try to avoid, use armhf images)

## Application examples
- Digital signage
- Video streams (Cameras, Livestreams, etc.)
- Grafana dashboard
- Public transport timetable
- Digital picture frame/slideshow
- Victron Solar dashboard

> [!TIP]
> Combining AnotterKiosk with an existing web CMS (like Typo3) is an excellent way to build a very flexible digital signage solution:  
> By configuring a hidden/special sub-page with a full-screen layout, employees can easily modify the digital signage solution themselves.
> Often teams are already trained on the existing content management systems, reducing training times.  
> It will also work without any monthly fees (unlike other hosted/SaaS/cloud-based digital signage solutions).

## Planned features:
- Raspberry Pi PXE/network boot support
- Network connectivity watchdog (configurable ping, etc. timeout)
- Automatic reboot at specified time

## Security considerations:
- Autossh does not check SSH host keys. This is okay-ish as long as the target server only allows tunneling, nothing else.
- nginx/PHP are allowed to use sudo/NOPASSWD (because it needs to query the VideoCore, manage service, etc.), more priviledge seperation would be nice
- due to the skeleton mechanism, the system has some ... creative permissions. some cleanup required.
- AnotterKiosk is not built in a reproducible/repeatible way. This is basically unfixable due to the nature of the build process.

## How-To / Installation guide

> [!IMPORTANT]  
> AnotterKiosk does not have an installer for x86 PCs. On PCs, you'll need to write the image to the storage somehow.
> Either write the storage media (like NVMe or SATA storage) externally using another PC or boot a Linux Live-ISO and use dd to flash the image.

Just like any other Raspberry Pi image:   
Download the current .img.xz file from the [Releases](https://github.com/Manawyrm/AnotterKiosk/releases) page and flash it to a storage device of your choice.  
SD cards, USB flash drives, USB SSDs, SATA SSDs, NVMe SSDs are all good options.  
You can use a tool like the [Raspberry Pi Imager](https://www.raspberrypi.com/software/), [BalenaEtcher](https://etcher.balena.io/), [Win32DiskImager](https://sourceforge.net/projects/win32diskimager/) or plain "dd" on \*nix-like systems.   
When using the latter two, make sure to extract the .gz compression first (using a tool like 7zip).  

After flashing, re-plug the storage device and open the FAT32 partition.  
Open the [`kioskbrowser.ini`](https://github.com/Manawyrm/AnotterKiosk/blob/main/kiosk_skeleton/boot/firmware/kioskbrowser.ini) file in a text editor and change everything to your needs.  
More complex WiFi setups (like WPA2-Enterprise) can be configured by creating a wpa_supplicant.conf.  
Adding your own SSH keys can be done by creating a authorized_keys file.  
If you want to use the autossh tunneling features, copy an SSH private key as either "id_rsa" or "id_ed25519".

## HTTP watchdog functionality
Browsers are complex, networks are unstable and software can be buggy.   
In order to get the highest reliability possible, self-hosted websites can be modified to include a heartbeat/watchdog functionality.
This works by requesting a certain http-endpoint from the website at some interval.   
If your page is being reloaded often (like with a <meta refresh=-header), you can just load the heartbeat-URL as an image:
```html
<img src="http://localhost/heartbeat.php" style="display: none;">
```

If your page stays on one page for a long time (or is just a single-page application), you might want to use AJAX requests to send a heartbeat:
```html
<script>
const req = new XMLHttpRequest();
setInterval(function() {
	req.open("GET", "http://localhost/heartbeat.php");
	req.send();
}, 2000);
</script>
```

Whenever the heartbeat stops (for whatever reason), the device will first restart the X11 environment (browser, window manager, etc.) and later (if it hasn't recovered) the whole system by rebooting.

## Inspiration / Other Kiosk-OSes:
- https://github.com/jareware/chilipie-kiosk/
- https://github.com/guysoft/FullPageOS
