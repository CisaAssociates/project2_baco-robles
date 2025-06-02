<?php
require_once '../includes/auth.php';
authenticate();
$user = getCurrentUser();
// Include database connection
require_once '../includes/db_connect.php';

// Get latest readings data
try {
    $stmt = $db->prepare("
        SELECT 
            r.id AS reading_id,
            r.reading_time,
            e.ec_value,
            e.salinity_ppt,
            e.temperature,
            g.latitude,
            g.longitude,
            d.device_id,
            d.name AS device_name
        FROM readings r
        JOIN ec_sensor_data e ON r.ec_data_id = e.id
        JOIN gps_data g ON r.gps_data_id = g.id
        JOIN devices d ON r.device_id = d.device_id
        ORDER BY r.reading_time DESC
        LIMIT 100
    ");
    $stmt->execute();
    $readings = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Convert readings to JSON-safe format
    foreach ($readings as &$reading) {
        $reading['salinity_ppt'] = floatval($reading['salinity_ppt']);
        $reading['ec_value'] = floatval($reading['ec_value']);
        $reading['temperature'] = floatval($reading['temperature']);
        $reading['latitude'] = floatval($reading['latitude']);
        $reading['longitude'] = floatval($reading['longitude']);
    }
} catch (PDOException $e) {
    error_log("Error fetching readings: " . $e->getMessage());
    $readings = [];
}

// Get all devices
try {
    $stmt = $db->prepare("
        SELECT device_id, name, status, last_seen
        FROM devices
        ORDER BY last_seen DESC
    ");
    $stmt->execute();
    $devices = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    error_log("Error fetching devices: " . $e->getMessage());
    $devices = [];
}

// Get mangrove species data
try {
    $stmt = $db->prepare("
        SELECT id, scientific_name, common_name, min_salinity, max_salinity, ideal_salinity
        FROM mangrove_species
        ORDER BY common_name
    ");
    $stmt->execute();
    $species = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    error_log("Error fetching species: " . $e->getMessage());
    $species = [];
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mangrove Salinity Monitoring Dashboard</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Chart.js -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/leaflet@1.7.1/dist/leaflet.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="../css/dashboard.css">
    
    <!-- Favicon -->
    <link rel="icon" href="../assets/favicon.ico" type="image/x-icon">
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
        <div class="container-fluid">
            <a class="navbar-brand" href="#">
                <img src="../assets/logo.png" alt="Logo" width="30" height="30" class="d-inline-block align-text-top me-2">
                Mangrove Salinity Monitor
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link active" href="#dashboard">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#devices">Devices</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#map">Map</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#species">Mangrove Species</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="logout.php">Logout</a>
                    </li>   
                </ul>
                <div class="d-flex">
                    <span class="navbar-text me-3">
                        <i class="bi bi-clock"></i> Last updated: <span id="last-updated">Now</span>
                    </span>
                    <button id="refresh-btn" class="btn btn-outline-light btn-sm">
                        <i class="bi bi-arrow-clockwise"></i> Refresh
                    </button>
                </div>
            </div>
        </div>
    </nav>

    <div class="container-fluid mt-4">
        <div class="row mb-4">
            <div class="col-12">
                <div class="card shadow-sm">
                    <div class="card-header bg-light">
                        <h5 class="card-title mb-0 text-capitalize">Welcome, <?php echo $user['username']; ?></h5>
                    </div>
                </div>
            </div>
        </div>

        <!-- Dashboard Overview -->
        <section id="dashboard" class="mb-5">
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow-sm">
                        <div class="card-header bg-light">
                            <h5 class="card-title mb-0">Salinity Monitoring Overview</h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-3 col-sm-6 mb-3">
                                    <div class="card bg-primary text-white">
                                        <div class="card-body">
                                            <h6 class="card-title">Active Devices</h6>
                                            <h2 class="card-text" id="active-devices-count">
                                                <?php 
                                                    $activeCount = 0;
                                                    foreach ($devices as $device) {
                                                        if ($device['status'] == 'active') $activeCount++;
                                                    }
                                                    echo $activeCount;
                                                ?>
                                            </h2>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-3 col-sm-6 mb-3">
                                    <div class="card bg-success text-white">
                                        <div class="card-body">
                                            <h6 class="card-title">Average Salinity</h6>
                                            <h2 class="card-text" id="avg-salinity">
                                                <?php 
                                                    $salinitySum = 0;
                                                    foreach ($readings as $reading) {
                                                        $salinitySum += floatval($reading['salinity_ppt']);
                                                    }
                                                    $avgSalinity = count($readings) > 0 ? $salinitySum / count($readings) : 0;
                                                    echo number_format($avgSalinity, 3);
                                                ?> ppt
                                            </h2>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-3 col-sm-6 mb-3">
                                    <div class="card bg-info text-white">
                                        <div class="card-body">
                                            <h6 class="card-title">Total Readings</h6>
                                            <h2 class="card-text" id="total-readings">
                                                <?php 
                                                    $stmt = $db->query("SELECT COUNT(*) FROM readings");
                                                    echo number_format($stmt->fetchColumn());
                                                ?>
                                            </h2>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-3 col-sm-6 mb-3">
                                    <div class="card bg-warning text-white">
                                        <div class="card-body">
                                            <h6 class="card-title">Recommended Species</h6>
                                            <h2 class="card-text" id="species-count">
                                                <?php echo count($species); ?>
                                            </h2>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <!-- Salinity Chart -->
                <div class="col-lg-8 mb-4">
                    <div class="card shadow-sm h-100">
                        <div class="card-header bg-light">
                            <h5 class="card-title mb-0">Salinity Trends</h5>
                        </div>
                        <div class="card-body">
                            <canvas id="salinity-chart" height="300"></canvas>
                        </div>
                    </div>
                </div>

                <!-- Latest Readings -->
                <div class="col-lg-4 mb-4">
                    <div class="card shadow-sm h-100">
                        <div class="card-header bg-light">
                            <h5 class="card-title mb-0">Latest Readings</h5>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-sm table-hover">
                                    <thead>
                                        <tr>
                                            <th>Time</th>
                                            <th>Device</th>
                                            <th>Salinity</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <?php foreach (array_slice($readings, 0, 10) as $reading): ?>
                                        <tr>
                                            <td><?php echo date('M d, H:i', strtotime($reading['reading_time'])); ?></td>
                                            <td><?php echo htmlspecialchars($reading['device_name']); ?></td>
                                            <td><?php echo number_format($reading['salinity_ppt'], 3); ?> ppt</td>
                                        </tr>
                                        <?php endforeach; ?>
                                        <?php if (empty($readings)): ?>
                                        <tr>
                                            <td colspan="3" class="text-center">No readings available</td>
                                        </tr>
                                        <?php endif; ?>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Devices Section -->
        <section id="devices" class="mb-5">
            <div class="card shadow-sm">
                <div class="card-header bg-light">
                    <h5 class="card-title mb-0">Monitoring Devices</h5>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Device ID</th>
                                    <th>Name</th>
                                    <th>Status</th>
                                    <th>Last Seen</th>
                                    <th>Last Reading</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($devices as $device): ?>
                                <tr>
                                    <td><?php echo htmlspecialchars($device['device_id']); ?></td>
                                    <td><?php echo htmlspecialchars($device['name']); ?></td>
                                    <td>
                                        <span class="badge <?php 
                                            echo $device['status'] == 'active' ? 'bg-success' : 
                                                ($device['status'] == 'inactive' ? 'bg-secondary' : 'bg-warning'); 
                                        ?>">
                                            <?php echo ucfirst($device['status']); ?>
                                        </span>
                                    </td>
                                    <td>
                                        <?php 
                                            echo $device['last_seen'] ? 
                                                date('M d, Y H:i', strtotime($device['last_seen'])) : 
                                                'Never'; 
                                        ?>
                                    </td>
                                    <td>
                                        <?php
                                            // Get the last reading for this device
                                            $deviceReadings = array_filter($readings, function($r) use ($device) {
                                                return $r['device_id'] == $device['device_id'];
                                            });
                                            $lastReading = reset($deviceReadings);
                                            echo $lastReading ? 
                                                number_format($lastReading['salinity_ppt'], 3) . ' ppt' : 
                                                'No data';
                                        ?>
                                    </td>
                                    <td>
                                        <button class="btn btn-sm btn-outline-primary view-device-btn" 
                                                data-device-id="<?php echo htmlspecialchars($device['device_id']); ?>">
                                            View Details
                                        </button>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                                <?php if (empty($devices)): ?>
                                <tr>
                                    <td colspan="6" class="text-center">No devices registered</td>
                                </tr>
                                <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>

        <!-- Map Section -->
        <section id="map" class="mb-5">
            <div class="card shadow-sm">
                <div class="card-header bg-light">
                    <h5 class="card-title mb-0">Salinity Map</h5>
                </div>
                <div class="card-body">
                    <div id="salinity-map" style="height: 500px;"></div>
                </div>
            </div>
        </section>

        <!-- Mangrove Species Section -->
        <section id="species" class="mb-5">
            <div class="card shadow-sm">
                <div class="card-header bg-light">
                    <h5 class="card-title mb-0">Mangrove Species</h5>
                </div>
                <div class="card-body">
                    <div class="row row-cols-1 row-cols-md-3 g-4">
                        <?php foreach ($species as $sp): ?>
                        <div class="col">
                            <div class="card h-100">
                                <div class="card-header">
                                    <h5 class="card-title"><?php echo htmlspecialchars($sp['common_name']); ?></h5>
                                    <h6 class="card-subtitle text-muted fst-italic"><?php echo htmlspecialchars($sp['scientific_name']); ?></h6>
                                </div>
                                <div class="card-body">
                                    <div class="salinity-range-wrapper mb-3">
                                        <label class="form-label">Salinity Tolerance Range</label>
                                        <div class="progress" style="height: 25px;">
                                            <?php 
                                                $range_min = $sp['min_salinity']; 
                                                $range_max = $sp['max_salinity'];
                                                $range_ideal = $sp['ideal_salinity'];
                                                $total_range = 45; // Maximum possible salinity for visualization
                                                
                                                $min_percent = ($range_min / $total_range) * 100;
                                                $max_percent = (($range_max - $range_min) / $total_range) * 100;
                                                $ideal_position = (($range_ideal - $range_min) / ($range_max - $range_min)) * 100;
                                                if ($ideal_position < 0) $ideal_position = 0;
                                                if ($ideal_position > 100) $ideal_position = 100;
                                            ?>
                                            <div class="progress-bar bg-light" role="progressbar" 
                                                style="width: <?php echo $min_percent; ?>%" 
                                                aria-valuenow="<?php echo $range_min; ?>" 
                                                aria-valuemin="0" aria-valuemax="<?php echo $total_range; ?>">
                                            </div>
                                            <div class="progress-bar bg-success position-relative" role="progressbar" 
                                                style="width: <?php echo $max_percent; ?>%" 
                                                aria-valuenow="<?php echo $range_max - $range_min; ?>" 
                                                aria-valuemin="0" aria-valuemax="<?php echo $total_range; ?>">
                                                <div class="ideal-marker" style="left: <?php echo $ideal_position; ?>%"></div>
                                            </div>
                                        </div>
                                        <div class="d-flex justify-content-between mt-1">
                                            <small><?php echo $range_min; ?> ppt</small>
                                            <small>Ideal: <?php echo $range_ideal; ?> ppt</small>
                                            <small><?php echo $range_max; ?> ppt</small>
                                        </div>
                                    </div>
                                </div>
                                <div class="card-footer">
                                    <button class="btn btn-sm btn-outline-primary view-species-btn" 
                                            data-species-id="<?php echo $sp['id']; ?>">
                                        View Details
                                    </button>
                                </div>
                            </div>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
            </div>
        </section>
    </div>

    <!-- JavaScript Data -->
    <script>
        // Initialize readings data
        const readingsData = <?php echo json_encode($readings); ?>;
        const devicesData = <?php echo json_encode($devices); ?>;
        const speciesData = <?php echo json_encode($species); ?>;
    </script>

    <!-- Footer -->
    <footer class="bg-light text-center text-lg-start mt-auto">
        <div class="text-center p-3" style="background-color: rgba(0, 0, 0, 0.05);">
            © 2025 Mangrove Salinity Monitoring System
        </div>
    </footer>

    <!-- Device Modal -->
    <div class="modal fade" id="device-modal" tabindex="-1" aria-labelledby="device-modal-label" aria-hidden="true">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="device-modal-label">Device Details</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div id="device-details-content">
                        Loading...
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Species Modal -->
    <div class="modal fade" id="species-modal" tabindex="-1" aria-labelledby="species-modal-label" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="species-modal-label">Species Details</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <div id="species-details-content">
                        Loading...
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>
    
    <!-- JavaScript Dependencies -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/leaflet@1.7.1/dist/leaflet.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/moment@2.29.1/moment.min.js"></script>
    
    <!-- Dashboard JavaScript -->
    <script src="../js/dashboard.js"></script>
    
    <!-- Chart Data -->
    <script>
        // Pass PHP data to JavaScript
        const readingsData = <?php echo json_encode($readings); ?>;
        const devicesData = <?php echo json_encode($devices); ?>;
        const speciesData = <?php echo json_encode($species); ?>;
    </script>
</body>
</html>
