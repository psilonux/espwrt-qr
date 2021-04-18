#!/bin/sh
#
# Script from @dibdot for patching luci login screen with wifi qr-code
# https://forum.openwrt.org/t/guest-wifi-qr-code-via-luci-app-commands/57180/18
#

. /lib/functions.sh

ssid_list=""
guest_ssid="WGuest"  ## Use "${1}" to add ssid as cli parameter
luci_file="/usr/lib/lua/luci/view/sysauth.htm"
backup_file="/usr/lib/lua/luci/view/sysauth.htm.backup"

handle_qrcode() {
    local device mode ssid pass
    device="$(uci_get "wireless" "${section}" "device")"
    mode="$(uci_get "wireless" "${section}" "mode")"
    ssid="$(uci_get "wireless" "${section}" "ssid")"
    pass="$(uci_get "wireless" "${section}" "key")"

    if [ -n "${ssid}" ] && [ -n "${pass}" ] && [ "${mode}"="ap" ] && \
	{ [ -z "${guest_ssid}" ] || [ "${guest_ssid}" = "${ssid}" ]; }
    then
	ssid_list="${ssid_list} ${ssid}"
	printf "%s\n" "<div class='ifacebox'>" >> "${luci_file}"
	printf "%s\n" "<div class='ifacebox-head-center'>" >> "${luci_file}"
	printf "%s\n" "<h5 style='padding-left:5px;padding-right:5px;line-height:24px;}'>${device}<br />${ssid}</h5>" >> "${luci_file}"
	printf "%s\n" "</div>" >> "${luci_file}"
	qrencode --inline --8bit --type=SVG --output=- "WIFI:S:${ssid};T:WPA;P:${pass};" >> "${luci_file}"
	printf "%s\n" "<h5 style='padding-left:5px;padding-right:5px;line-height:24px;}'>Password:<br />${pass}</h5>" >> "${luci_file}"
	printf "%s\n" "</div>" >> "${luci_file}"
    fi
}

if [ ! -f "${backup_file}" ]
then
    cp -p "${luci_file}" "${backup_file}"
fi
head -n-1 "${backup_file}" > "${luci_file}"

config_load wireless
config_foreach handle_qrcode

printf "%s\n" "<%+footer%>" >> "${luci_file}"
logger -t qr-guest "Luci login screen patched with QR-code for SSID: ${ssid}"
