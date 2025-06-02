<?php
/**
 * Salinity Monitoring Device Simulator
 * 
 * This script simulates an ESP8266 device sending EC sensor and GPS data to the API.
 * Use this for testing the system without physical hardware.
 * 
 * Usage: php simulate_device.php [device_id] [num_readings] [interval_seconds]
 * Example: php simulate_device.php SAL001 10 5
 */

// Default parameters
$device_id = isset($argv[1]) ? $argv[1] : 'SAL001';
$num_readings = isset($argv[2]) ? intval($argv[2]) : 10;
$interval_seconds = isset($argv[3]) ? intval($argv[3]) : 5;

// API endpoint
$api_url = 'http://localhost/ec/api/data.php';

echo "Salinity Monitoring Device Simulator\n";
echo "===================================\n";
echo "Device ID: $device_id\n";
echo "Number of readings: $num_readings\n";
echo "Interval: $interval_seconds seconds\n";
echo "API URL: $api_url\n";
echo "===================================\n\n";

// Generate and send readings
for ($i = 1; $i <= $num_readings; $i++) {
    // Generate random values within realistic ranges
    $ec_value = mt_rand(5000, 50000) / 100; // 50-500 µS/cm
    $salinity_ppt = $ec_value / 2000; // Convert EC to salinity (approximate)
    $temperature = mt_rand(220, 320) / 10; // 22-32°C
    
    // Generate GPS coordinates (around Southeast Asia mangrove areas)
    // Default to Jakarta Bay area coordinates
    $base_lat = 6.1;
    $base_lng = 106.8;
    
    // Add small random offset (within ~2km)
    $lat_offset = (mt_rand(-200, 200) / 10000);
    $lng_offset = (mt_rand(-200, 200) / 10000);
    
    $latitude = $base_lat + $lat_offset;
    $longitude = $base_lng + $lng_offset;
    
    // Prepare JSON data
    $data = [
        'device_id' => $device_id,
        'ec_value' => $ec_value,
        'salinity_ppt' => $salinity_ppt,
        'temperature' => $temperature,
        'latitude' => $latitude,
        'longitude' => $longitude
    ];
    
    // Encode as JSON
    $json_data = json_encode($data);
    
    echo "Sending reading #$i: \n";
    echo "  EC Value: {$ec_value} µS/cm\n";
    echo "  Salinity: {$salinity_ppt} ppt\n";
    echo "  Temperature: {$temperature}°C\n";
    echo "  Location: {$latitude}, {$longitude}\n";
    
    // Send to API
    $ch = curl_init($api_url);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
    curl_setopt($ch, CURLOPT_POSTFIELDS, $json_data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Content-Length: ' . strlen($json_data)
    ]);
    
    $response = curl_exec($ch);
    $status_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "  Response (HTTP $status_code): " . trim($response) . "\n\n";
    
    // Wait before sending next reading
    if ($i < $num_readings) {
        echo "Waiting {$interval_seconds} seconds...\n";
        sleep($interval_seconds);
    }
}

echo "Simulation complete!\n";
?>
