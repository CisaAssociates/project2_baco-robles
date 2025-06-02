/*
  Salinity Monitoring Device for Mangrove Planting
  With Real-Time Monitoring System
  
  This sketch reads EC (electrical conductivity) sensor data and GPS coordinates,
  then sends them to a cloud server for monitoring and mangrove species recommendation.
  
  Hardware:
  - ESP8266 NodeMCU
  - EC Salinity Sensor (Analog)
  - NEO-6M GPS Module
  - Power supply (3.7V LiPo battery recommended)
*/

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <TinyGPS++.h>
#include <SoftwareSerial.h>
#include <EEPROM.h>

// Wi-Fi settings
const char* ssid = "DESKTOP-9IQK6CJ 6188";       // Replace with your Wi-Fi SSID
const char* password = "mariangamay"; // Replace with your Wi-Fi password

// Server settings
const char* serverUrl = "http://192.168.51.194/ec/api/data.php"; // Replace with your server URL

// Device settings
String deviceID = "SAL001";  // Unique device identifier

// EC Sensor settings
#define EC_PIN A0           // EC sensor analog pin
#define EC_POWER_PIN D1     // Digital pin to power the EC sensor (to prevent electrolysis)
float K = 1.0;              // Cell constant for EC sensor (adjust after calibration)
float tempCoefficient = 0.019; // Temperature compensation coefficient
float temperature = 25.0;   // Default temperature for EC calculation (°C)

// GPS settings
#define GPS_RX D6           // GPS module RX pin connected to this pin
#define GPS_TX D7           // GPS module TX pin connected to this pin
TinyGPSPlus gps;            // GPS parser object
SoftwareSerial gpsSerial(GPS_RX, GPS_TX); // GPS serial connection

// Variable to store sensor readings
float ecValue = 0.0;        // EC value in µS/cm
float salinityPPT = 0.0;    // Salinity in parts per thousand (ppt)
double latitude = 0.0;      // GPS latitude
double longitude = 0.0;     // GPS longitude

// Timing variables
unsigned long lastReadingTime = 0;
const unsigned long readingInterval = 30000; // Read sensors every 30 seconds
unsigned long lastUploadTime = 0;
const unsigned long uploadInterval = 300000; // Upload data every 5 minutes

// Power saving settings
bool deepSleepEnabled = false;  // Set to true to enable deep sleep between readings
const int sleepTimeMinutes = 10; // Deep sleep time in minutes

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  Serial.println("\nSalinity Monitoring System Initializing...");
  
  // Initialize pins
  pinMode(EC_PIN, INPUT);
  pinMode(EC_POWER_PIN, OUTPUT);
  digitalWrite(EC_POWER_PIN, LOW); // Keep sensor powered off initially
  
  // Initialize GPS serial
  gpsSerial.begin(9600);
  
  // Initialize EEPROM for storing calibration data
  EEPROM.begin(512);
  
  // Load calibration values from EEPROM if available
  loadCalibrationData();
  
  // Connect to Wi-Fi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  Serial.print("Connecting to Wi-Fi");
  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWi-Fi Connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWi-Fi connection failed. Will try again later.");
  }
  
  // Synchronize time with NTP server (optional for timestamping)
  // configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  
  Serial.println("System ready!");
  Serial.println("Reading EC sensor and GPS coordinates...");
}

void loop() {
  unsigned long currentMillis = millis();
  
  // Read sensors at the specified interval
  if (currentMillis - lastReadingTime >= readingInterval) {
    lastReadingTime = currentMillis;
    
    // Read EC sensor
    readECSensor();
    
    // Read GPS coordinates
    readGPSData();
    
    // Print readings to serial monitor
    printSensorReadings();
  }
  
  // Upload data to server at the specified interval
  if (currentMillis - lastUploadTime >= uploadInterval) {
    lastUploadTime = currentMillis;
    
    // Attempt to connect to Wi-Fi if not connected
    if (WiFi.status() != WL_CONNECTED) {
      reconnectWiFi();
    }
    
    // Upload data to server
    if (WiFi.status() == WL_CONNECTED) {
      uploadData();
    }
    
    // Enter deep sleep mode if enabled
    if (deepSleepEnabled) {
      Serial.println("Entering deep sleep mode...");
      ESP.deepSleep(sleepTimeMinutes * 60 * 1000000); // Convert minutes to microseconds
    }
  }
  
  // Process any incoming serial commands
  processSerialCommands();
  
  // Read GPS data when available
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }
}

void readECSensor() {
  // Power on the EC sensor
  digitalWrite(EC_POWER_PIN, HIGH);
  delay(100); // Wait for the sensor to stabilize
  
  // Take multiple readings and average them
  int numReadings = 10;
  int ecRawSum = 0;
  
  for (int i = 0; i < numReadings; i++) {
    ecRawSum += analogRead(EC_PIN);
    delay(10);
  }
  
  // Calculate average raw reading
  float ecRawAvg = ecRawSum / (float)numReadings;
  
  // Convert raw reading to voltage
  float voltage = ecRawAvg * (3.3 / 1023.0); // For 3.3V reference
  
  // Convert voltage to EC using K value and temperature compensation
  ecValue = calculateEC(voltage, temperature);
  
  // Convert EC to salinity in ppt (parts per thousand)
  // Approximate conversion: 1 ppt ≈ 2000 µS/cm at 25°C
  salinityPPT = ecValue / 2000.0;
  
  // Power off the EC sensor to prevent electrolysis
  digitalWrite(EC_POWER_PIN, LOW);
}

float calculateEC(float voltage, float temperature) {
  // Convert voltage to EC in µS/cm
  float rawEC = (voltage / K) * 1000.0;
  
  // Apply temperature compensation
  float compensatedEC = rawEC / (1.0 + tempCoefficient * (temperature - 25.0));
  
  return compensatedEC;
}

void readGPSData() {
  // Check if valid GPS data is available
  if (gps.location.isValid()) {
    latitude = gps.location.lat();
    longitude = gps.location.lng();
  } else {
    // If no valid GPS data, try to read for a while
    unsigned long gpsStartTime = millis();
    while (millis() - gpsStartTime < 5000) { // Try for 5 seconds
      while (gpsSerial.available() > 0) {
        if (gps.encode(gpsSerial.read()) && gps.location.isValid()) {
          latitude = gps.location.lat();
          longitude = gps.location.lng();
          return;
        }
      }
    }
    
    // If still no valid data
    if (!gps.location.isValid()) {
      Serial.println("Warning: No valid GPS data available");
    }
  }
}

void printSensorReadings() {
  Serial.println("\n--- Sensor Readings ---");
  Serial.print("EC Value: ");
  Serial.print(ecValue);
  Serial.println(" µS/cm");
  
  Serial.print("Salinity: ");
  Serial.print(salinityPPT);
  Serial.println(" ppt");
  
  if (gps.location.isValid()) {
    Serial.print("GPS Location: ");
    Serial.print(latitude, 6);
    Serial.print(", ");
    Serial.println(longitude, 6);
  } else {
    Serial.println("GPS: No valid data");
  }
  
  Serial.println("---------------------");
}

void uploadData() {
  // Create JSON document
  DynamicJsonDocument doc(256);
  
  doc["device_id"] = deviceID;
  doc["ec_value"] = ecValue;
  doc["salinity_ppt"] = salinityPPT;
  doc["temperature"] = temperature;
  
  // Only include GPS data if valid
  if (gps.location.isValid()) {
    doc["latitude"] = latitude;
    doc["longitude"] = longitude;
  }
  
  // Serialize JSON to string
  String jsonString;
  serializeJson(doc, jsonString);
  
  // Send data to server
  WiFiClient client;
  HTTPClient http;
  
  http.begin(client, serverUrl);
  http.addHeader("Content-Type", "application/json");
  
  int httpResponseCode = http.POST(jsonString);
  
  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("Server Response: " + response);
    Serial.println("Data uploaded successfully!");
  } else {
    Serial.print("Error on uploading data. Error code: ");
    Serial.println(httpResponseCode);
  }
  
  http.end();
}

void reconnectWiFi() {
  Serial.print("Reconnecting to Wi-Fi");
  
  WiFi.disconnect();
  WiFi.begin(ssid, password);
  
  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 10) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWi-Fi Reconnected!");
  } else {
    Serial.println("\nWi-Fi reconnection failed. Will try again later.");
  }
}

void loadCalibrationData() {
  // Read calibration data from EEPROM
  if (EEPROM.read(0) == 'C') { // Check if calibration data exists
    EEPROM.get(1, K);
    EEPROM.get(5, tempCoefficient);
    
    Serial.println("Loaded calibration data from EEPROM:");
    Serial.print("K value: ");
    Serial.println(K);
    Serial.print("Temperature coefficient: ");
    Serial.println(tempCoefficient);
  } else {
    Serial.println("No calibration data found in EEPROM. Using defaults.");
  }
}

void saveCalibrationData() {
  // Save calibration data to EEPROM
  EEPROM.write(0, 'C'); // Calibration data flag
  EEPROM.put(1, K);
  EEPROM.put(5, tempCoefficient);
  EEPROM.commit();
  
  Serial.println("Calibration data saved to EEPROM.");
}

void processSerialCommands() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    
    if (command.startsWith("calibrate")) {
      // Parse calibration parameters
      // Format: calibrate:k=1.2:temp=0.019
      if (command.indexOf("k=") > 0) {
        int kStart = command.indexOf("k=") + 2;
        int kEnd = command.indexOf(":", kStart);
        if (kEnd < 0) kEnd = command.length();
        
        String kValue = command.substring(kStart, kEnd);
        K = kValue.toFloat();
        
        Serial.print("K value set to: ");
        Serial.println(K);
      }
      
      if (command.indexOf("temp=") > 0) {
        int tempStart = command.indexOf("temp=") + 5;
        int tempEnd = command.indexOf(":", tempStart);
        if (tempEnd < 0) tempEnd = command.length();
        
        String tempValue = command.substring(tempStart, tempEnd);
        tempCoefficient = tempValue.toFloat();
        
        Serial.print("Temperature coefficient set to: ");
        Serial.println(tempCoefficient);
      }
      
      // Save the new calibration values
      saveCalibrationData();
    }
    else if (command == "sleep on") {
      deepSleepEnabled = true;
      Serial.println("Deep sleep mode enabled.");
    }
    else if (command == "sleep off") {
      deepSleepEnabled = false;
      Serial.println("Deep sleep mode disabled.");
    }
    else if (command == "read") {
      readECSensor();
      readGPSData();
      printSensorReadings();
    }
    else if (command == "upload") {
      if (WiFi.status() == WL_CONNECTED) {
        uploadData();
      } else {
        Serial.println("Wi-Fi not connected. Cannot upload data.");
      }
    }
    else if (command == "help") {
      Serial.println("\nAvailable commands:");
      Serial.println("  calibrate:k=<value>:temp=<value> - Set calibration values");
      Serial.println("  sleep on/off - Enable/disable deep sleep mode");
      Serial.println("  read - Take a sensor reading");
      Serial.println("  upload - Upload data to server");
      Serial.println("  help - Show this help message");
    }
  }
}