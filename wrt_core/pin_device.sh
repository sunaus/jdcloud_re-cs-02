#!/bin/bash
# jdcloud_re-cs-02 only (from the VIKINGYFY branch Scripts/PinDevice.sh).
# Run in the LibWrt source root, after the first make defconfig.
set -euo pipefail

DEVICE_CFG='CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02'
NPROC="$(nproc 2>/dev/null || echo 4)"

disable_other_devices() {
  local line sym
  while read -r line; do
    sym="${line%%=y}"
    [ "$sym" = "$DEVICE_CFG" ] && continue
    sed -i "s|^${sym}=y|# ${sym} is not set|" .config
  done < <(grep -E '^CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_.*=y' .config || true)
}

enable_device() {
  if grep -q "^${DEVICE_CFG}=y" .config; then
    :
  elif grep -q "^# ${DEVICE_CFG} is not set" .config; then
    sed -i "s|^# ${DEVICE_CFG} is not set|${DEVICE_CFG}=y|" .config
  else
    echo "${DEVICE_CFG}=y" >> .config
  fi
}

grep -q '^CONFIG_TARGET_MULTI_PROFILE=y' .config || echo 'CONFIG_TARGET_MULTI_PROFILE=y' >> .config

disable_other_devices
enable_device
make defconfig -j"$NPROC"

# defconfig may turn on another default device again, redo once
disable_other_devices
enable_device
make defconfig -j"$NPROC"

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
