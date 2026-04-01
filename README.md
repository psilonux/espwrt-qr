The idea for this little project was to keep the Guest Wi-Fi secure but still practical for visitors at home.

When people come over to visit and ask for the Wi-Fi password, it's good practise to offer them internet acces via a sepearte guest vlan.

Not everyone can be trusted these days, so I rotate random generated passwords each day for the guest wifi.

To avoid typing random characters, a qr-code thats automatically connects to the guest wifi, is displayed via a cheap and tiny LCD-screen.

A cron script on Openwrt changes the guest wifi password every night with a random generated 12 character string.
A QR-code is generated on the Luci login page and also a simple text file in the www folder with the QR-code payload.
The ESP8266 together with a ST7789 LCD-screen refreshes the payload over the main wifi and the display generates a QR-code which a phone can scan.
