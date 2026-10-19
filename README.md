# AX6600 (jdcloud_re-cs-02) - LibWrt NSS build

Branch `libwrt` builds `jdcloud_re-cs-02` straight from [LiBwrt/LibWrt](https://github.com/LiBwrt/LibWrt) `25.12-nss`.
[ZqinKing/wrt_release](https://github.com/ZqinKing/wrt_release) is **not** used at build time; the `wrt_core/` layout and a few fixes are only mirrored from it so they are easy to keep in sync.

The other branches (`VIKINGYFY`, `VIKINGYFY-ppe`) are unchanged.

## How it works

`.github/workflows/LIBWRT.yml`: clone LibWrt (optionally pinned) -> `feeds update/install` -> mirrored fixes -> assemble `.config` -> `make defconfig` -> pin to jdcloud_re-cs-02 -> download -> compile -> release.

| File | Purpose |
|---|---|
| `wrt_core/compilecfg/jdcloud_ipq60xx_libwrt.ini` | LibWrt repo / branch, optional `COMMIT_HASH`, fragments (`nss`) |
| `wrt_core/deconfig/jdcloud_ipq60xx_libwrt.config` | jdcloud_re-cs-02 + package list from the VIKINGYFY branch `Config/GENERAL.txt` (ath11k firmware uses LibWrt names, no `-ddwrt`) |
| `wrt_core/deconfig/compile_base.config` | build options only (`CONFIG_USE_APK=y`) |
| `wrt_core/deconfig/fragments/nss.config` | NSS options mirrored from wrt_release, without `sqm-scripts-nss` and `kmod-ath11k-pci=m` |
| `wrt_core/patches/991_custom_settings` | first-boot: hostname `AX6600`, Australia/Sydney, bootstrap theme, empty root password |
| `wrt_core/patches/992_set-wifi-uci.sh` | first-boot Wi-Fi: SSID `AX6600` / `12345678`, country `AU` |
| `wrt_core/pin_device.sh` | makes sure only jdcloud_re-cs-02 is built (from the VIKINGYFY branch `PinDevice.sh`) |

Mirrored from wrt_release (done inline in the workflow): `luci-app-athena-led` (NONGFAH), uci-defaults install, `remove_something_nss_kmod`, `fix_kconfig_recursive_dependency`.
Not mirrored: NSS pbuf/diag tweaks, irq affinity script, cpuusage, smartdns/argon/mosdns updates, opkg distfeeds.

## Run

GitHub only offers "Run workflow" for a workflow file that also exists on `main`, so `main` carries a stub `LIBWRT.yml`.
Actions -> LIBWRT -> Run workflow, with **Use workflow from: `libwrt`**.

- `source_commit`: optional LiBwrt/LibWrt commit to pin
- `config_only`: stop after `make defconfig` and only publish the resulting `.config`

## Still different from the VIKINGYFY branch

- `fullconenat-sonic`, `luci-app-fullconenat-sonic`, `stuntman-client` stay in the config but may not exist in LibWrt (unknown symbols are dropped by defconfig). Check the published `config-*.txt`.
- LAN IP, Wi-Fi channels / widths / power are the LibWrt / wrt_release defaults.
- Untested: first run should be `config_only`.
