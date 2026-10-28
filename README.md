# AX6600 (jdcloud_re-cs-02) firmware builds

Firmware CI for the JDCloud Athena AX6600 (`jdcloud_re-cs-02`, IPQ6010) with Qualcomm NSS offload. `main` only holds this README and the shared workflows; each build lives on its own branch.

## Branches

| Branch | Source | Based on |
|--------|--------|----------|
| [`VIKINGYFY`](../../tree/VIKINGYFY) | ImmortalWrt [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) `main` (NSS-DP + NSS) | Simplified from [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) |
| [`VIKINGYFY-ppe`](../../tree/VIKINGYFY-ppe) | ImmortalWrt [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) `ppe` (PPE) | Simplified from [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) |
| [`JuliusBairaktaris`](../../tree/JuliusBairaktaris) | OpenWrt [JuliusBairaktaris/openwrt-ppe-nss](https://github.com/JuliusBairaktaris/openwrt-ppe-nss) `ppe-nss` (PPE wired offload + NSS Wi-Fi offload; only the NSS firmware from [nss-packages](https://github.com/JuliusBairaktaris/nss-packages)) | Fork of [JuliusBairaktaris/Qualcommax_NSS_Builder](https://github.com/JuliusBairaktaris/Qualcommax_NSS_Builder), re-cs-02 only |

## Build

Actions → pick the workflow → **Run workflow** → set **Use workflow from** to the branch:

| Workflow | Branch | Output |
|----------|--------|--------|
| `QCA-ALL` | `VIKINGYFY` | factory.bin + sysupgrade.bin |
| `QCA-ALL-ppe` | `VIKINGYFY-ppe` | factory.bin + sysupgrade.bin |
| `WRT-TEST` | `VIKINGYFY` | test / config-only builds |
| `Build` | `JuliusBairaktaris` | sysupgrade.bin only, release tag `ppe-nss-*` |

The workflow files on `main` are stubs. GitHub only offers **Run workflow** for a file that also exists on the default branch, and running a stub on `main` just fails with a pointer to the right branch.

## Maintenance

- `Cache-Clean` (weekly and manual) deletes every Actions cache.
- `Auto-Clean` (manual) deletes **every** release, tag and workflow run, for both branches.
- Sync the `JuliusBairaktaris` branch from upstream with `git merge` from `JuliusBairaktaris/Qualcommax_NSS_Builder` `main`; it shares that history.

## Test results (2026-10-28)

Setup: the AX6600 `wan` port is a trunk to a VLAN switch (VLAN 2, 100). Two ways of handling the VLANs were tried:

- **trunk**: 802.1Q sub-interfaces (`wan.N`), one bridge per VLAN (`brlan.N`), no bridge VLAN filtering.
- **vlan filtering**: `wan` is a bridge port, bridge VLAN filtering enabled, `wan` tagged for all VLANs, LAN ports untagged (PVID).

Rows 1-4 were tested on 2026-10-18, rows 5-6 on 2026-10-28.

| # | Date | Branch | Mode | Wired clients | Offload | Notes |
|---|------|--------|------|---------------|---------|-------|
| 1 | 2026-10-18 | `VIKINGYFY` | trunk | Working | NSS | Recommended |
| 2 | 2026-10-18 | `VIKINGYFY-ppe` | trunk | Working | PPE offload does not work | |
| 3 | 2026-10-18 | `VIKINGYFY-ppe` | vlan filtering | No internet | PPE offload works | |
| 4 | 2026-10-18 | `JuliusBairaktaris` (+ GCC bias PLL patch) | trunk | WAN works, LAN not checked | PPE offload does not work | Stops responding after some hours (up to ~8 h); only a power cycle recovers it. Also reported: with vlan filtering, wired clients have no internet |
| 5 | 2026-10-28 | `JuliusBairaktaris` (OpenWrt SNAPSHOT r0+37782-243def1174, kernel 6.18.55) | trunk | Working | PPE offload does not work | |
| 6 | 2026-10-28 | `JuliusBairaktaris` (same image as row 5) | vlan filtering | Working (untagged to tagged traffic OK) | PPE offload works; NSS Wi-Fi offload works | Only `radio2` (QCN9074, 5 GHz) enabled. Stability test started 2026-10-28 |

`VIKINGYFY` + vlan filtering: result not recorded.

A stock OpenWrt router (RAX3000) with the same VLAN filtering configuration works with the same switch, so the switch and the VLAN plan are not the problem.

### Findings

- **PPE does not probe on current OpenWrt snapshots for IPQ60xx.** OpenWrt commit `5df1a6ab80` ("qualcommax: ipq60xx: pass UNIPHY clocks directly to GCC") removed the global-name fallback for the GCC parents `bias_pll_cc_clk` and `bias_pll_nss_noc_clk`. `nss_ppe_clk_src` then cannot get its 300 MHz, the PPE does not probe and no DSA port comes up. The patch `0904-clk-qcom-ipq6018-fall-back-to-the-global-bias-PLL-clock-names` adds the fallback back (same approach as `gcc-ipq8074`). **Update 2026-10-28:** fixed upstream. OpenWrt main has `qualcommax: ipq60xx: pass CMN PLL clocks to GCC` (`0d245fd`, 2026-10-20), and `ppe-nss` carries the `.name` fallback as its own patch (`0193`), so the local `0904` patch was removed from this repo.
- **With vlan filtering on the PPE builds, unicast leaves the trunk port untagged.** Captured on the other side of the trunk (RAX3000): frames the router originates itself (`ping -I brlan.2`) and broadcasts carry `802.1Q vlan 2`; unicast forwarded from an untagged LAN port to `wan` arrives without a tag, so the far end drops it. The bridge VLAN table (`bridge vlan show`) and the FDB (both MACs on the right port and VLAN) are correct. **Update 2026-10-28:** fixed. Frames classified by the port's PVID left a tagged port with VID 0; `qca_ppe: give a PVID-classified frame the VLAN's VID` (openwrt/openwrt issue #25904, merged with PR #24806 on 2026-10-26) fixes it. Untagged to tagged traffic works in row 6.
- **Not caused by flow offload.** `flow_offloading` and `flow_offloading_hw` set to `0` and the nft flowtables empty: no change. `ethtool -K ... txvlan off` has no effect (`wan` reports the VLAN offload flags as fixed).
- **Suspected, not confirmed:** the egress tagging mode programmed into the PPE for the trunk port. A similar symptom was fixed for qca8k in openwrt/openwrt PR #25968 (patch 0961, egress mode "untouched"), but that is the qca8k driver, not qca-ppe. **Update 2026-10-28:** not the cause; see the PVID fix above.
- **PPE offload follows the mode:** it works with vlan filtering (the LAN ports and `wan` are bridge ports of the switch) and does not work with trunk, where `wan.N` is a software 802.1Q device and not a switch port. This fits the counters in `/sys/kernel/debug/3a000000.ppe/offload` (`ingress_not_switch_port`, `egress_not_switch_port`), which should be checked to confirm. So the PPE branches currently offer either working wired clients or working offload, not both. **Update 2026-10-28:** same behaviour on rows 5 and 6 (trunk: no offload; vlan filtering: offload works). The counters were not re-checked for the trunk case.
- **Hang (`JuliusBairaktaris`):** the hardware watchdog does not reboot the router, which suggests the kernel and user space are still running and the network datapath (PPE/EDMA) is stuck. A similar freeze is reported for the AX3600 in JuliusBairaktaris/openwrt-ppe-nss issue #45. Next step: a watchdog script that ping-checks two LAN hosts, saves `/proc/interrupts`, `ethtool -S eth0` and the PPE debugfs counters, then triggers a panic so pstore keeps the call stack. **Update 2026-10-28:** not re-tested yet; the row 6 stability run started on 2026-10-28.
- **NSS Wi-Fi offload on IPQ6010 (2026-10-28):** the first boot left `/etc/nss-wifi.pending` ("the last bring-up did not complete") and the offload stayed off. After removing it and rebooting, the bring-up completed (`bring-up survived`), `ath11k` `nss_offload` is `Y`, and the QCN9074 access point works with the offload. The cause of the first failed bring-up is unknown.

### Current recommendation

Use `VIKINGYFY` in trunk mode (row 1) until the `JuliusBairaktaris` vlan filtering build (row 6) has run stably for several days. `VIKINGYFY` `main` had no new commits since 2026-10-15 (checked 2026-10-24). Use the PPE trunk builds only for testing.

### Notes for the keepalived scripts

- Per-VLAN bridges can be named `brlan.2`, `brlan.100` (netifd creates them as real bridges when declared with `option type 'bridge'`).
- UCI section names cannot contain dots: keep a section name such as `br_wan` or `brlan100` and put the dotted name in `option name`; `uci get network.<section>.ports` uses the section name.
- The FDB clean-up must target the right device: `dev wan vlan 100` for vlan filtering, `dev wan.100` for trunk (no `vlan` argument, `self` does not apply to 802.1Q devices).

### Related

- openwrt/openwrt PR #25968 (draft): qca8k qca-8021q tagging and DSA fixes.
- openwrt/openwrt PR #24806 (merged 2026-10-26): qca_ppe host-driven PPE offload, includes the PVID VLAN fix.
- openwrt/openwrt issue #25904: VLAN-aware bridge, untagged to tagged unicast.
- JuliusBairaktaris/openwrt-ppe-nss issue #45: AX3600 freezing.
- JuliusBairaktaris/openwrt-ppe-nss issue #52: `nss-wifi-drv` build error `DSA_TAG_PROTO_QCA_8021Q`.
