<?php
/**
 * Database Connection
 * For Salinity Monitoring System
 */

// Database configuration
$db_host = 'localhost';
$db_name = 'pj2_baro_db';
$db_user = 'pj2_baro';     // Change to your MySQL username
$db_pass = 'Project2_2025';         // Change to your MySQL password

// Create database connection
try {
    $db = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8", $db_user, $db_pass);
    // Set PDO error mode to exception
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    // Use an emulated prepares feature for older MySQL versions
    $db->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
} catch(PDOException $e) {
    error_log("Database Connection Error: " . $e->getMessage());
    die("Database connection failed. Please check the connection settings.");
}

/**
 * Log system messages to database
 * 
 * @param string $message Log message
 * @param string $level Log level (info, warning, error, critical)
 * @param string $device_id Optional device ID
 * @return bool Success status
 */
function logSystemMessage($message, $level = 'info', $device_id = null) {
    global $db;
    
    try {
        $stmt = $db->prepare("INSERT INTO system_log (device_id, log_level, message) VALUES (:device_id, :level, :message)");
        $stmt->bindParam(':device_id', $device_id);
        $stmt->bindParam(':level', $level);
        $stmt->bindParam(':message', $message);
        return $stmt->execute();
    } catch(PDOException $e) {
        error_log("Error logging to system_log: " . $e->getMessage());
        return false;
    }
}

/**
 * Get recommended mangrove species based on salinity
 * 
 * @param float $salinity_ppt Salinity in parts per thousand
 * @param int $limit Maximum number of recommendations to return
 * @return array Array of recommended species
 */
function getMangroveRecommendations($salinity_ppt, $limit = 3) {
    global $db;
    
    try {
        // Query species suitable for the given salinity
        $stmt = $db->prepare("
            SELECT id, scientific_name, common_name, min_salinity, max_salinity, ideal_salinity, 
                   description, image_url,
                   ABS(ideal_salinity - :salinity) AS salinity_diff
            FROM mangrove_species
            WHERE :salinity BETWEEN min_salinity AND max_salinity
            ORDER BY salinity_diff ASC
            LIMIT :limit
        ");
        
        $stmt->bindParam(':salinity', $salinity_ppt, PDO::PARAM_STR);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        $recommendations = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Calculate confidence score based on how close the salinity is to ideal
        foreach ($recommendations as &$species) {
            $ideal = $species['ideal_salinity'];
            $min = $species['min_salinity'];
            $max = $species['max_salinity'];
            $range = $max - $min;
            
            // Calculate distance from ideal as percentage of range
            $distance = abs($ideal - $salinity_ppt);
            $normalized_distance = $range > 0 ? $distance / $range : 0;
            
            // Convert to confidence score (1 = perfect match, 0 = at the edge of tolerance)
            $species['confidence'] = max(0, 1 - $normalized_distance);
        }
        
        return $recommendations;
    } catch(PDOException $e) {
        error_log("Error getting mangrove recommendations: " . $e->getMessage());
        return [];
    }
}
?>
