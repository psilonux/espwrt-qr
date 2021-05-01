#include <Arduino.h>
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecureBearSSL.h>
#include <TFT_eSPI.h>
#include <qrcode.h>

const char *ssid = "WWiFi";                          // The SSID (name) of the native Wi-Fi network you want to connect to
const char *password = "Tottie&Niels&Frodo";                  // The password of the native Wi-Fi network
const char *url = "https://openwrt-apu4.lan/guest.txt";  // The URL to a ASCII text file with the wifi qr-code string

// Fingerprint in hex format of the url ssl certificate
// https://stackoverflow.com/questions/5164804/get-certificate-fingerprint-of-https-server-from-command-line
const uint8_t fingerprint[20] = {0x42, 0x37, 0xd9, 0xf6, 0xfc, 0x3a, 0x1a, 0x11, 0x29, 0x0c, 0x7f, 0x32, 0x22, 0xcc, 0xea, 0x0b, 0xfc, 0x11, 0x71, 0x78};

// Time interval between refresh
const int interval = 60;
const unsigned long SECOND = 1000; // 1 second = 1000 milliseconds
//const unsigned long HOUR = 3600 * SECOND;

ESP8266WiFiMulti WiFiMulti;

TFT_eSPI tft = TFT_eSPI();
QRcode qrcode(&tft);

void setup()
{
    Serial.begin(115200);

    Serial.println();
    Serial.println();
    Serial.println();

    for (uint8_t t = 4; t > 0; t--)
    {
        Serial.printf("[SETUP]\t WAIT %d...\n", t);
        Serial.flush();
        delay(1000);
    }

    Serial.printf("[TFT]\t Initialising screen...\n");
    tft.init();
    tft.setRotation(3);

    Serial.printf("[QR]\t Initialising qrcode...\n");
    qrcode.init();

    Serial.printf("[WIFI]\t Start connecting to %s\n", ssid);
    WiFiMulti.addAP(ssid, password);
    while (WiFiMulti.run() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println();
    Serial.printf("[WIFI]\t Connected, IP address: ");
    Serial.println(WiFi.localIP());
}

void loop()
{
    // wait for WiFi connection
    if ((WiFiMulti.run() == WL_CONNECTED))
    {

        std::unique_ptr<BearSSL::WiFiClientSecure> client(new BearSSL::WiFiClientSecure);

        client->setFingerprint(fingerprint);

        HTTPClient https;

        Serial.printf("[HTTPS]\t Trying to scrape %s\n", url);
        if (https.begin(*client, url))
        { // HTTPS

            Serial.printf("[HTTPS]\t Sending HTTP Header\n");
            // start connection and send HTTP header
            int httpCode = https.GET();

            // httpCode will be negative on error
            if (httpCode > 0)
            {
                // HTTP header has been send and Server response header has been handled
                Serial.printf("[HTTPS]\t GET... Response code: %d\n", httpCode);

                // file found at server
                if (httpCode == HTTP_CODE_OK || httpCode == HTTP_CODE_MOVED_PERMANENTLY)
                {
                    String payload = https.getString();
                    qrcode.create(payload);
                    Serial.printf("[QR]\t Generating payload: ");
                    Serial.println(payload);
                }
            }
            else
            {
                Serial.printf("[HTTPS]\t GET... failed, error: %s\n", https.errorToString(httpCode).c_str());
            }

            https.end();
        }
        else
        {
            Serial.printf("[HTTPS]\t Unable to connect to webserver!\n");
        }
    }

    Serial.printf("[SETUP]\t Wait %i seconds before next check!\n", interval);
    delay(interval * SECOND);
}