#!/bin/bash
# OpenWrt for jdcloud_re-cs-02 only got sysupgrade by default and optional initramfs, and no factory.bin for U-Boot Web
# same as ImmortalWrt/VIKINGYFY: add EmmcImage + factory image

set -euo pipefail

ROOT="${1:-.}"
MK="$ROOT/target/linux/qualcommax/image/ipq60xx.mk"

if [ ! -f "$MK" ]; then
	echo "PatchFactory: missing $MK"
	exit 1
fi

if grep -q 'Device/jdcloud_re-cs-02' "$MK" && grep -A12 'Device/jdcloud_re-cs-02' "$MK" | grep -q 'Device/EmmcImage'; then
	echo "PatchFactory: jdcloud_re-cs-02 already has EmmcImage"
	exit 0
fi

python3 - "$MK" <<'PY'
from pathlib import Path
import re
import sys

mk = Path(sys.argv[1])
text = mk.read_text()
pat = re.compile(
    r"define Device/jdcloud_re-cs-02\n.*?^endef\n",
    re.M | re.S,
)
repl = """define Device/jdcloud_re-cs-02
\t$(call Device/FitImage)
\t$(call Device/EmmcImage)
\tDEVICE_VENDOR := JDCloud
\tDEVICE_MODEL := RE-CS-02
\tSOC := ipq6010
\tBLOCKSIZE := 64k
\tKERNEL_SIZE := 6144k
\tDEVICE_DTS_CONFIG := config@cp03-c3
\tDEVICE_PACKAGES := ath11k-firmware-qcn9074 ipq-wifi-jdcloud_re-cs-02 kmod-ath11k-pci
\tIMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | append-metadata
endef
"""
new, n = pat.subn(repl, text, count=1)
if n != 1:
    sys.exit(f"PatchFactory: failed to patch Device/jdcloud_re-cs-02 (matches={n})")
mk.write_text(new)
print("PatchFactory: added EmmcImage + factory.bin for jdcloud_re-cs-02")
PY
