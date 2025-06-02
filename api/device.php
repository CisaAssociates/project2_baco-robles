<?php
/**
 * API Endpoint for Device Details and Recommendations
 * 
 * This script provides detailed information about a specific device
 * and generates mangrove species recommendations based on its readings.
 */

// Include database connection
require_once '../includes/db_connect.php';

// Set headers for API response
header('Content-Type: application/json');

// Get device ID from request
$device_id = isset($_GET['id']) ? $_GET['id'] : null;

if (!$device_id) {
    http_response_code(400); // Bad Request
    echo json_encode(['status' => 'error', 'message' => 'Device ID is required']);
    exit;
}

try {
    // Get device information
    $stmt = $db->prepare("
        SELECT * FROM devices 
        WHERE device_id = :device_id
    ");
    $stmt->bindParam(':device_id', $device_id);
    $stmt->execute();
    
    $device = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$device) {
        http_response_code(404); // Not Found
        echo json_encode(['status' => 'error', 'message' => 'Device not found']);
        exit;
    }
    
    // Get the latest readings for this device
    $stmt = $db->prepare("
        SELECT 
            r.id AS reading_id,
            r.reading_time,
            e.ec_value,
            e.salinity_ppt,
            e.temperature,
            g.latitude,
            g.longitude
        FROM readings r
        JOIN ec_sensor_data e ON r.ec_data_id = e.id
        JOIN gps_data g ON r.gps_data_id = g.id
        WHERE r.device_id = :device_id
        ORDER BY r.reading_time DESC
        LIMIT 20
    ");
    $stmt->bindParam(':device_id', $device_id);
    $stmt->execute();
    
    $readings = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get the latest salinity reading for recommendations
    $latestSalinity = null;
    if (!empty($readings)) {
        $latestSalinity = $readings[0]['salinity_ppt'];
    }
    
    // Get recommendations if we have salinity data
    $recommendations = [];
    if ($latestSalinity !== null) {
        $recommendations = getMangroveRecommendations($latestSalinity);
    }
    
    // Prepare the response
    $response = [
        'status' => 'success',
        'device' => $device,
        'readings' => $readings,
        'recommendations' => $recommendations
    ];
    
    // Return JSON response
    echo json_encode($response);
    
} catch (PDOException $e) {
    // Log error
    error_log('Database error in device.php: ' . $e->getMessage());
    
    // Return error response
    http_response_code(500); // Internal Server Error
    echo json_encode(['status' => 'error', 'message' => 'Database error']);
}
?>
