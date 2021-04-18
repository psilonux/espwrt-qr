#!/bin/sh
#
# This script updates the given (guest) SSID with a random password and reloads the configuration
# A file in www folder is updated with the string needed to generate a qr-code for wifi login

ssid="***REMOVED***"
title="WiFi-code for ${ssid}"
html="/www/guest.html"
txt="/www/guest.txt"
pswd=$(cat /dev/urandom | \
		env LC_CTYPE=C tr -dc _ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjklmnpqrstuvwxyz23456789- | \
		head -c 12;)

qr_wifi(){
    local payload
    payload="WIFI:S:${ssid};T:WPA;P:${pswd};"
    return payload
}

handle_html(){
    printf "%s\n" "<!DOCTYPE html>" > "${html}"
    printf "%s\n" "<html>" >> "${html}"
    printf "\t%s\n" "<head><title>${title}</title></head>" >> "${html}"
    printf "\t%s\n" "<body><p>${1}</p></body>" >> "${html}"
    printf "%s\n" "</html>" >> "${html}"
}

handle_txt(){
    printf "%s" "${1}" > ${txt}
}

for i in $(seq 0 4); do # Try 4 interfaces for guest ssid
    if [ $(uci get wireless.@wifi-iface[$i].ssid) == ${ssid} ]; then
#	uci set wireless.@wifi-iface[${i}].key=${pswd}
#	uci commit wireless
#	wifi
	logger -t qr-guest "Wifi password for SSID: ${ssid} changed to ${pswd}"
	sleep 1
	handle_txt "WIFI:S:${ssid};T:WPA;P:${pswd};"
	logger -t qr-guest "The file ${txt} has been updatet with a new password!"
	break
    fi
done;

