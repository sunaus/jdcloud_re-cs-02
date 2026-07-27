#!/bin/bash
# jdcloud_re-cs-02 only
# after make defconfig, use (cwd = openwrt root)

set -euo pipefail

DEVICE_CFG='CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02'

# ensure multi-profile + localhost y
sed -i \
	-e 's/^# CONFIG_TARGET_MULTI_PROFILE is not set/CONFIG_TARGET_MULTI_PROFILE=y/' \
	-e 's/^CONFIG_TARGET_MULTI_PROFILE=n/CONFIG_TARGET_MULTI_PROFILE=y/' \
	.config || true
grep -q '^CONFIG_TARGET_MULTI_PROFILE=y' .config || echo 'CONFIG_TARGET_MULTI_PROFILE=y' >> .config

# turn off other ipq60xx devices
while read -r line; do
	sym="${line%%=y}"
	[ "$sym" = "$DEVICE_CFG" ] && continue
	sed -i "s|^${sym}=y|# ${sym} is not set|" .config
done < <(grep -E '^CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_.*=y' .config || true)

# force JDCloud Athena AX6600
if grep -q "^${DEVICE_CFG}=y" .config; then
	:
elif grep -q "^# ${DEVICE_CFG} is not set" .config; then
	sed -i "s|^# ${DEVICE_CFG} is not set|${DEVICE_CFG}=y|" .config
else
	echo "${DEVICE_CFG}=y" >> .config
fi

make defconfig -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

# defconfig may turn on other default device again, redo one
while read -r line; do
	sym="${line%%=y}"
	[ "$sym" = "$DEVICE_CFG" ] && continue
	sed -i "s|^${sym}=y|# ${sym} is not set|" .config
done < <(grep -E '^CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_.*=y' .config || true)
if grep -q "^# ${DEVICE_CFG} is not set" .config; then
	sed -i "s|^# ${DEVICE_CFG} is not set|${DEVICE_CFG}=y|" .config
elif ! grep -q "^${DEVICE_CFG}=y" .config; then
	echo "${DEVICE_CFG}=y" >> .config
fi
make defconfig -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

echo "==== selected devices ===="
grep -E '^CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_.*=y' .config || true

if ! grep -q "^${DEVICE_CFG}=y" .config; then
	echo "ERROR: failed to enable jdcloud_re-cs-02"
	exit 1
fi
extra="$(grep -E '^CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_.*=y' .config | grep -v 'jdcloud_re-cs-02' || true)"
if [ -n "$extra" ]; then
	echo "ERROR: unexpected devices still enabled:"
	echo "$extra"
	exit 1
fi

echo "device pin ok: jdcloud_re-cs-02 only"
