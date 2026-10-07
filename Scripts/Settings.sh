#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# remove luci-app-attendedsysupgrade
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +
# update default theme
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" {} +
# update flash.js IP
find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" -exec sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" {} +
# add timestamp
find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" -exec sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" {} +

WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_UC" ]; then
	# change ssid
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	# change wifi password
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
# update default IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
# update default hostname
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
# update default timezone Australia/Sydney
sed -i "s/timezone='.*'/timezone='AEST-10AEDT,M10.1.0,M4.1.0\/3'/g" $CFG_FILE
sed -i "s/zonename='.*'/zonename='Australia\/Sydney'/g" $CFG_FILE
# if using uci set, overwrite as well
sed -i "s/set system\..*timezone=.*/set system.system.timezone='AEST-10AEDT,M10.1.0,M4.1.0\/3'/g" $CFG_FILE
sed -i "s/set system\..*zonename=.*/set system.system.zonename='Australia\/Sydney'/g" $CFG_FILE

# no root password
SHADOW_FILE="./package/base-files/files/etc/shadow"
if [ -f "$SHADOW_FILE" ]; then
	sed -i 's/^root:[^:]*:/root::/' "$SHADOW_FILE"
fi
PASSWD_FILE="./package/base-files/files/etc/passwd"
if [ -f "$PASSWD_FILE" ]; then
	sed -i 's/^root:[^:]*:/root::/' "$PASSWD_FILE"
fi

# update config files
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
# bootstrap no standalone *-config package; other themes will use only
if [[ "$WRT_THEME" != "bootstrap" ]]; then
	echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config
fi

# import private module
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

# other manual plugin
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

# change for QUALCOMMAX
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	# change Q6 size when no wifi
	if [[ "$WRT_WIFI" == "WIFI-NO" ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi
