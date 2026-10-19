# AX6600 (jdcloud_re-cs-02) - LibWrt NSS build

Branch `libwrt` builds only `jdcloud_ipq60xx_libwrt` with [ZqinKing/wrt_release](https://github.com/ZqinKing/wrt_release) (pinned commit) on top of [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x) `25.12-nss`.

The other branches (`VIKINGYFY`, `VIKINGYFY-ppe`) are unchanged.

## How it works

`.github/workflows/LIBWRT.yml` checks out the pinned wrt_release, deletes every other device, copies the `wrt_core/` files of this branch over it and runs `./build.sh jdcloud_ipq60xx_libwrt`.

| File | Purpose |
|---|---|
| `wrt_core/compilecfg/jdcloud_ipq60xx_libwrt.ini` | source repo / branch, fragments (`nss` only) |
| `wrt_core/deconfig/jdcloud_ipq60xx_libwrt.config` | jdcloud_re-cs-02 + package list copied from the VIKINGYFY branch `Config/GENERAL.txt` |
| `wrt_core/deconfig/compile_base.config` | build options only (`CONFIG_USE_APK=y`, no extra apps) |
| `wrt_core/deconfig/fragments/nss.config` | upstream NSS options, without `sqm-scripts-nss` and `kmod-ath11k-pci=m` |
| `wrt_core/patches/991_custom_settings` | first-boot defaults: hostname `AX6600`, timezone Australia/Sydney, bootstrap theme, empty root password |
| `wrt_core/patches/992_set-wifi-uci.sh` | first-boot Wi-Fi: SSID `AX6600` / `12345678` on every radio, country `AU` |

## Run

GitHub only offers "Run workflow" for a workflow file that also exists on `main`, so `main` carries a stub `LIBWRT.yml`.
Actions -> LIBWRT -> Run workflow, with **Use workflow from: `libwrt`**.

- `upstream_ref`: wrt_release commit (default: pinned `90a9591`)
- `source_commit`: optional LiBwrt/openwrt-6.x commit to pin
- `config_only`: stop after `make defconfig` and only publish the resulting `.config`

## Still different from the VIKINGYFY branch

- `fullconenat-sonic`, `luci-app-fullconenat-sonic`, `stuntman-client` stay in the config but may not exist in the LiBwrt feeds (unknown symbols are dropped by defconfig). Check the published `config-*.txt`.
- LAN IP is 192.168.1.1 (wrt_release default). Wi-Fi channels / widths / power are the wrt_release defaults.
- wrt_release scripts were written around opkg (`install_opkg_distfeeds`, `fix_opkg_check`); `CONFIG_USE_APK=y` is not what upstream sets for LiBwrt, so check the first build.
