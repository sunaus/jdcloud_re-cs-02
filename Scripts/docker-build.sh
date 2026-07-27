#!/bin/bash
# Docker: Same as GitHub QCA-ALL
# Usage: In container or /build to run bash /ci/Scripts/docker-build.sh

set -euo pipefail

CI_DIR="${CI_DIR:-/ci}"
WRT_DIR="${WRT_DIR:-/build/wrt}"

export WRT_THEME="${WRT_THEME:-bootstrap}"
export WRT_NAME="${WRT_NAME:-AX6600}"
export WRT_SSID="${WRT_SSID:-AX6600}"
export WRT_WORD="${WRT_WORD:-12345678}"
export WRT_IP="${WRT_IP:-192.168.1.1}"
export WRT_MARK="${WRT_MARK:-local}"
export WRT_DATE="${WRT_DATE:-$(date +%y.%m.%d-%H.%M.%S)}"
export WRT_CONFIG="${WRT_CONFIG:-IPQ60XX-WIFI-YES}"
export WRT_TARGET="${WRT_TARGET:-qualcommax}"
export GITHUB_WORKSPACE="$CI_DIR"
export GITHUB_ENV="${GITHUB_ENV:-/tmp/github_env}"
: > "$GITHUB_ENV"

JOBS="${JOBS:-$(nproc)}"
REPO_URL="${REPO_URL:-https://github.com/VIKINGYFY/immortalwrt.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"

mkdir -p /build
cd /build

if [ ! -d "$WRT_DIR/.git" ]; then
	echo "==> clone $REPO_URL ($REPO_BRANCH)"
	git clone --depth=1 --single-branch --branch "$REPO_BRANCH" "$REPO_URL" "$WRT_DIR"
else
	echo "==> reuse existing tree: $WRT_DIR"
fi

cd "$WRT_DIR"

echo "==> feeds"
# OpenWrt: remove unused video feed
for f in feeds.conf.default feeds.conf; do
	[ -f "$f" ] && sed -i -E '/(^|[[:space:]])video([[:space:]]|$)/d' "$f" || true
done
./scripts/feeds update -a
./scripts/feeds install -a

echo "==> packages / handles"
(
	cd package
	bash "$CI_DIR/Scripts/Packages.sh"
	bash "$CI_DIR/Scripts/Handles.sh"
)

echo "==> patch factory image"
bash "$CI_DIR/Scripts/PatchFactory.sh" "$WRT_DIR"

echo "==> config"
rm -f .config
cat "$CI_DIR/Config/${WRT_CONFIG}.txt" "$CI_DIR/Config/GENERAL.txt" > .config
bash "$CI_DIR/Scripts/Settings.sh"
make defconfig -j"$JOBS"
bash "$CI_DIR/Scripts/PinDevice.sh"

echo "==> download"
make tools/flock/compile -j1
make tools/libdeflate/compile -j1 V=s
make tools/zstd/compile -j1
make download -j"$JOBS" || make download -j1 V=s

echo "==> compile"
make -j"$JOBS" || make -j1 V=s

echo "==> done"
ls -lh bin/targets/qualcommax/ipq60xx/*jdcloud_re-cs-02* 2>/dev/null || ls -lh bin/targets/qualcommax/ipq60xx/
