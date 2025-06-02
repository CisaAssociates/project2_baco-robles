<?php
/**
 * API Endpoint for Receiving Sensor Data
 * 
 * This script receives JSON data from ESP8266 devices
 * and stores it in the database.
 */

// Include database connection
require_once '../includes/db_connect.php';

// Set headers for API response
header('Content-Type: application/json');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); // Method Not Allowed
    echo json_encode(['status' => 'error', 'message' => 'Only POST method is allowed']);
    exit;
}

// Get JSON data from request body
$json_data = file_get_contents('php://input');

// Decode JSON data
$data = json_decode($json_data, true);

// Validate received data
if (!$data || !isset($data['device_id']) || !isset($data['ec_value'])) {
    http_response_code(400); // Bad Request
    echo json_encode(['status' => 'error', 'message' => 'Invalid data format']);
    logSystemMessage('Invalid data received: ' . $json_data, 'warning');
    exit;
}

// Start a transaction for data integrity
$db->beginTransaction();

try {
    // Check if device exists
    $stmt = $db->prepare("SELECT device_id FROM devices WHERE device_id = :device_id");
    $stmt->bindParam(':device_id', $data['device_id']);
    $stmt->execute();
    
    // If device doesn't exist, create it
    if ($stmt->rowCount() == 0) {
        $stmt = $db->prepare("INSERT INTO devices (device_id, name, description) VALUES (:device_id, :name, :description)");
        $stmt->bindParam(':device_id', $data['device_id']);
        $device_name = 'Device ' . $data['device_id']; // Default name
        $stmt->bindParam(':name', $device_name);
        $description = 'Auto-registered device';
        $stmt->bindParam(':description', $description);
        $stmt->execute();
        
        logSystemMessage('New device registered: ' . $data['device_id'], 'info');
    }
    
    // Update device last_seen timestamp
    $stmt = $db->prepare("UPDATE devices SET last_seen = NOW(), status = 'active' WHERE device_id = :device_id");
    $stmt->bindParam(':device_id', $data['device_id']);
    $stmt->execute();
    
    // Store raw data
    $stmt = $db->prepare("INSERT INTO arduino_data (device_id, raw_data) VALUES (:device_id, :raw_data)");
    $stmt->bindParam(':device_id', $data['device_id']);
    $stmt->bindParam(':raw_data', $json_data);
    $stmt->execute();
    
    // Store EC sensor data
    $stmt = $db->prepare("INSERT INTO ec_sensor_data (device_id, ec_value, salinity_ppt, temperature) 
                         VALUES (:device_id, :ec_value, :salinity_ppt, :temperature)");
    $stmt->bindParam(':device_id', $data['device_id']);
    $stmt->bindParam(':ec_value', $data['ec_value']);
    $stmt->bindParam(':salinity_ppt', $data['salinity_ppt']);
    
    // Use provided temperature or default to 25°C
    $temperature = isset($data['temperature']) ? $data['temperature'] : 25.0;
    $stmt->bindParam(':temperature', $temperature);
    $stmt->execute();
    
    $ec_data_id = $db->lastInsertId();
    $gps_data_id = null;
    
    // Store GPS data if available
    if (isset($data['latitude']) && isset($data['longitude'])) {
        $stmt = $db->prepare("INSERT INTO gps_data (device_id, latitude, longitude) 
                             VALUES (:device_id, :latitude, :longitude)");
        $stmt->bindParam(':device_id', $data['device_id']);
        $stmt->bindParam(':latitude', $data['latitude']);
        $stmt->bindParam(':longitude', $data['longitude']);
        $stmt->execute();
        
        $gps_data_id = $db->lastInsertId();
        
        // Create a reading record linking EC and GPS data
        if ($ec_data_id && $gps_data_id) {
            $stmt = $db->prepare("INSERT INTO readings (device_id, ec_data_id, gps_data_id) 
                                 VALUES (:device_id, :ec_data_id, :gps_data_id)");
            $stmt->bindParam(':device_id', $data['device_id']);
            $stmt->bindParam(':ec_data_id', $ec_data_id);
            $stmt->bindParam(':gps_data_id', $gps_data_id);
            $stmt->execute();
            
            $reading_id = $db->lastInsertId();
            
            // Generate mangrove recommendations based on salinity
            $recommendations = getMangroveRecommendations($data['salinity_ppt']);
            
            // Store recommendations
            if (!empty($recommendations)) {
                foreach ($recommendations as $species) {
                    $stmt = $db->prepare("INSERT INTO recommendations (reading_id, species_id, confidence) 
                                         VALUES (:reading_id, :species_id, :confidence)");
                    $stmt->bindParam(':reading_id', $reading_id);
                    $stmt->bindParam(':species_id', $species['id']);
                    $stmt->bindParam(':confidence', $species['confidence']);
                    $stmt->execute();
                }
            }
        }
    }
    
    // Commit transaction
    $db->commit();
    
    // Prepare response
    $response = [
        'status' => 'success',
        'message' => 'Data recorded successfully',
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    // Add recommendations to response if available
    if (isset($recommendations) && !empty($recommendations)) {
        $response['recommendations'] = array_map(function($species) {
            return [
                'species' => $species['common_name'],
                'scientific_name' => $species['scientific_name'],
                'confidence' => round($species['confidence'] * 100) . '%'
            ];
        }, $recommendations);
    }
    
    // Return success response
    http_response_code(200);
    echo json_encode($response);
    
    // Log successful data reception
    logSystemMessage('Data received from device: ' . $data['device_id'], 'info', $data['device_id']);
    
} catch (PDOException $e) {
    // Rollback transaction on error
    $db->rollBack();
    
    // Return error response
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Database error']);
    
    // Log error
    logSystemMessage('Database error processing data: ' . $e->getMessage(), 'error', $data['device_id'] ?? null);
    error_log('Database error in data.php: ' . $e->getMessage());
}
?>
