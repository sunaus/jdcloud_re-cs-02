# AX6600 (jdcloud_re-cs-02) OpenWRT-CI

Based on [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) simplification (aligned with commit `8795a08`), dedicated to JDCloud Athena AX6600 (`jdcloud_re-cs-02`).

## Features

- **SONiC Fullcone NAT**: Kernel-level Full Cone NAT (NAT1) via `fullconenat-sonic` and `luci-app-fullconenat-sonic`
- **STUN Client**: `stuntman-client` included for testing NAT mapping and filtering types
- **LED Control**: JDCloud Athena front RGB LED control via `luci-app-athena-led`

## source code

- **Default**: ImmortalWrt (VIKINGYFY) - https://github.com/VIKINGYFY/immortalwrt.git (`main`, NSS-DP)
- ImmortalWrt: https://github.com/immortalwrt/immortalwrt.git
- OpenWrt: snapshot testing **Green light without LAN/Wi-Fi**; `WRT-TEST` for testing only, maybe not working

## Packages

- Device: `Config/IPQ60XX-WIFI-YES.txt` → Only `jdcloud_re-cs-02`
- Packages: `Config/GENERAL.txt` (simplified, syncthing/podman/samba/acme/ddns/smartdns/sqm/wg/netifyd can be installed later)
- Driver: `ath11k-firmware-*-ddwrt`, `ipq-wifi-jdcloud_re-cs-02`, `luci-app-athena-led`

## Flash

| Files | Usage |
|-------|-------|
| `*-squashfs-factory.bin` | For U-Boot Web (`http://192.168.1.1/`) |
| `*-squashfs-sysupgrade.bin` | Flash from luci or cli |

By default: `192.168.1.1`, connect to **1G LAN** (Not 2.5G WAN). Wi‑Fi: `AX6600` / `12345678`

## Compile

- Actions → `QCA-ALL` (Full) or `WRT-TEST`
- Clean: `Auto-Clean` / `Cache-Clean`

## U-Boot

- https://github.com/chenxin527/uboot-ipq60xx-emmc-build.git

