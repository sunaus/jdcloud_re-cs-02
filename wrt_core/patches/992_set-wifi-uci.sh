#!/bin/sh

# jdcloud re-cs-02 (AX6600) only: SSID AX6600 / password 12345678 on every radio,
# same as the VIKINGYFY branch. Channels, widths and power are the wrt_release defaults.
# Country is AU (wrt_release uses US).

board_name=$(cat /tmp/sysinfo/board_name)

configure_wifi() {
	local radio=$1
	local channel=$2
	local htmode=$3
	local txpower=$4
	local ssid=$5
	local key=$6
	local encryption=${7:-"psk2+ccmp"}
	local now_encryption=$(uci get wireless.default_radio${radio}.encryption)
	if [ -n "$now_encryption" ] && [ "$now_encryption" != "none" ]; then
		return 0
	fi
	uci -q batch <<EOF
set wireless.radio${radio}.channel="${channel}"
set wireless.radio${radio}.htmode="${htmode}"
set wireless.radio${radio}.mu_beamformer='1'
set wireless.radio${radio}.country='AU'
set wireless.radio${radio}.txpower="${txpower}"
set wireless.radio${radio}.cell_density='0'
set wireless.radio${radio}.disabled='0'
set wireless.default_radio${radio}.ssid="${ssid}"
set wireless.default_radio${radio}.encryption="${encryption}"
set wireless.default_radio${radio}.key="${key}"
set wireless.default_radio${radio}.ieee80211k='1'
set wireless.default_radio${radio}.time_advertisement='2'
set wireless.default_radio${radio}.time_zone='AEST-10'
set wireless.default_radio${radio}.bss_transition='1'
set wireless.default_radio${radio}.wnm_sleep_mode='1'
set wireless.default_radio${radio}.wnm_sleep_mode_no_keys='1'
EOF
}

jdc_ax6600_wifi_cfg() {
	configure_wifi 0 149 HE80 22 'AX6600' '12345678'
	configure_wifi 1 1 HE20 22 'AX6600' '12345678'
	configure_wifi 2 44 HE160 23 'AX6600' '12345678'
}

case "${board_name}" in
jdcloud,ax6600 | \
	jdcloud,re-cs-02)
	jdc_ax6600_wifi_cfg
	;;
*)
	exit 0
	;;
esac

uci commit wireless
/etc/init.d/network restart
