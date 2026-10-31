# OpenWrt PPE/NSS for the JDCloud RE-CS-02

Prebuilt OpenWrt sysupgrade images for the **JDCloud RE-CS-02** (Athena AX6600, IPQ6010, 1 GB RAM), with Qualcomm PPE hardware offload for wired traffic and NSS offload for Wi-Fi.

This repository is a single-device fork of [Qualcommax_NSS_Builder](https://github.com/JuliusBairaktaris/Qualcommax_NSS_Builder). It is **not** the upstream project: it builds only the RE-CS-02, only on manual dispatch, and carries the local choices listed below. The upstream device list, release names (`ppe-nss-mesh-*`, `ppe-offload-test`, `edma-nss-*`) and donation links do not apply to the images published here.

> [!IMPORTANT]
> The default `root` password is **`root`**. Change it right after the first login (`passwd`, or System > Administration in LuCI), and do not expose the router to the internet before you do.

## Install

There is no factory image. The router must already run OpenWrt or ImmortalWrt.

1. Download `...-jdcloud_re-cs-02-squashfs-sysupgrade.bin` from the [releases](../../releases) page.
2. Flash it from LuCI (System > Backup / Flash Firmware), or over ssh:

```sh
sysupgrade -n /tmp/openwrt-qualcommax-ipq60xx-jdcloud_re-cs-02-squashfs-sysupgrade.bin
```

Coming from ImmortalWrt, flash without keeping settings (`-n`). Between images from this repository, keeping settings is fine.

Do not upgrade with `attendedsysupgrade` or `owut`. The sysupgrade server builds stock OpenWrt, which has no NSS and a different kernel.

## First boot defaults

| Setting | Value |
|---|---|
| Login | `root` / `root` |
| Hostname | `AX6600` |
| Timezone | `Australia/Sydney` |

The root password is set on first boot only while it is still empty, so a password you set later survives a sysupgrade that keeps settings. Hostname and timezone are likewise applied once.

## What this build contains

The images are built by GitHub Actions from the `ppe-nss` branch of [openwrt-ppe-nss](https://github.com/JuliusBairaktaris/openwrt-ppe-nss). Only the NSS firmware comes from [nss-packages](https://github.com/JuliusBairaktaris/nss-packages). The `luci-app-ppe-qos` package comes from a luci fork, and `luci-app-athena-led` (the front LED screen) is taken from [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt).

Differences from upstream's defaults:

- **SSH:** Dropbear instead of OpenSSH.
- **SQM:** `sqm-scripts` and `luci-app-sqm` are left out. Install them later if you want them; the `hw_ppe.qos` script exists only in the patched `sqm-scripts` this build carries.
- **BCP38:** `luci-app-bcp38` is not included.
- **Storage:** the eMMC overlay is formatted as F2FS on first boot (`kmod-fs-f2fs`, `f2fs-tools`), so settings survive a reboot. Disk and USB storage tools are included.
- **Kernel modules:** this kernel is not the one the OpenWrt kmods feed is built for, so a kmod cannot be installed later with `apk`. Everything needed (WireGuard, PPPoE, conntrack, ath11k, USB storage and more) is already in the image.
- **LuCI:** `luci-light` with the Bootstrap theme, plus `luci-app-usteer` and `luci-app-package-manager`.

## Status and recovery

Wired offload is the fw4 hardware flow offloading, switched on at first boot. It is what drives the PPE. `grep -c HW_OFFLOAD /proc/net/nf_conntrack` counts the flows in the PPE.

NSS Wi-Fi offload is on by default. Turn it off with:

```sh
uci set nss-wifi.general.offload='0'; uci commit nss-wifi; reboot
```

`logread -e nss-wifi` shows the bring-up. If the router boots but 192.168.1.1 does not answer, see [patch-20261016.md](patch-20261016.md) for a past IPQ6018 clock bug (now fixed upstream).

## Build it yourself

Fork this repository, then run **Actions > Build > Run workflow**. The workflow is manual only and builds one device. Parameters are in the `env:` block of [build.yml](.github/workflows/build.yml) and in [devices/jdcloud_re-cs-02/config](devices/jdcloud_re-cs-02/config).

Each run publishes a release tagged `ppe-nss-<timestamp>-<run id>` and keeps the newest two. A failed build discards its draft release.

[docs/CUSTOMIZE.md](docs/CUSTOMIZE.md) covers build options and overlays. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) describes the CI pipeline.

## Credits

- [Julius Bairaktaris](https://github.com/JuliusBairaktaris) for Qualcommax_NSS_Builder, openwrt-ppe-nss and nss-packages.
- [Christian Marangi (Ansuel)](https://github.com/Ansuel) for the upstream EDMA and PPE drivers.
- [Robert Marko (robimarko)](https://github.com/robimarko) for maintaining the OpenWrt qualcommax target.
- [qosmio](https://github.com/qosmio) for NSS development and the Wi-Fi offload patches.
- [VIKINGYFY](https://github.com/VIKINGYFY/immortalwrt) for `luci-app-athena-led` and the package set this image follows.

Upstream issues and donations belong to the upstream maintainer, not to this fork.

## License

[GPL-2.0](LICENSE), as OpenWrt.
