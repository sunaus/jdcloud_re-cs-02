# AX6600 (jdcloud_re-cs-02) firmware builds

Firmware CI for the JDCloud Athena AX6600 (`jdcloud_re-cs-02`, IPQ6010) with Qualcomm NSS offload. `main` only holds this README and the shared workflows; each build lives on its own branch.

## Branches

| Branch | Source | Based on |
|--------|--------|----------|
| [`VIKINGYFY`](../../tree/VIKINGYFY) | ImmortalWrt [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) `main` (NSS-DP + NSS) | Simplified from [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) |
| [`JuliusBairaktaris`](../../tree/JuliusBairaktaris) | OpenWrt [JuliusBairaktaris/openwrt-nss-edma](https://github.com/JuliusBairaktaris/openwrt-nss-edma) `nss-edma-rework` (NSS on upstream EDMA/PPE) | Fork of [JuliusBairaktaris/Qualcommax_NSS_Builder](https://github.com/JuliusBairaktaris/Qualcommax_NSS_Builder), re-cs-02 only |

## Build

Actions → pick the workflow → **Run workflow** → set **Use workflow from** to the branch:

| Workflow | Branch | Output |
|----------|--------|--------|
| `QCA-ALL` | `VIKINGYFY` | factory.bin + sysupgrade.bin |
| `WRT-TEST` | `VIKINGYFY` | test / config-only builds |
| `Build` | `JuliusBairaktaris` | sysupgrade.bin only, release tag `edma-nss-*` |

The workflow files on `main` are stubs. GitHub only offers **Run workflow** for a file that also exists on the default branch, and running a stub on `main` just fails with a pointer to the right branch.

## Maintenance

- `Cache-Clean` (weekly and manual) deletes every Actions cache.
- `Auto-Clean` (manual) deletes **every** release, tag and workflow run, for both branches.
- Sync the `JuliusBairaktaris` branch from upstream with `git merge` from `JuliusBairaktaris/Qualcommax_NSS_Builder` `main`; it shares that history.
