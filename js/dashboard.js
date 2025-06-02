/**
 * Dashboard JavaScript for Mangrove Salinity Monitoring System
 * Handles data visualization, map integration, and dynamic content
 */

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize the chart for salinity trends
    initSalinityChart();
    
    // Initialize the map with readings data
    initSalinityMap();
    
    // Set up event listeners
    initEventListeners();
    
    // Update last updated time
    updateLastUpdatedTime();
});

/**
 * Initialize the salinity trend chart using Chart.js
 */
function initSalinityChart() {
    // Get chart context
    const ctx = document.getElementById('salinity-chart').getContext('2d');
    
    // Process data for the chart
    const chartLabels = [];
    const salinityData = [];
    const ecData = [];
    
    // Use only the last 20 readings in reverse order (oldest to newest)
    const chartReadings = readingsData.slice(0, 20).reverse();
    
    chartReadings.forEach(reading => {
        // Format date for x-axis
        const readingDate = new Date(reading.reading_time);
        chartLabels.push(moment(readingDate).format('MM/DD HH:mm'));
        
        // Add salinity and EC values
        const salinity = reading.salinity_ppt || 0;
        const ecValue = reading.ec_value || 0;
        
        salinityData.push(salinity);
        ecData.push(ecValue / 1000); // Convert to mS/cm for scale
    });
    
    // Create chart
    const salinityChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: chartLabels,
            datasets: [
                {
                    label: 'Salinity (ppt)',
                    data: salinityData,
                    backgroundColor: 'rgba(40, 167, 69, 0.2)',
                    borderColor: 'rgba(40, 167, 69, 1)',
                    borderWidth: 2,
                    tension: 0.3,
                    pointRadius: 3,
                    pointBackgroundColor: 'rgba(40, 167, 69, 1)'
                },
                {
                    label: 'EC (mS/cm)',
                    data: ecData,
                    backgroundColor: 'rgba(0, 123, 255, 0.2)',
                    borderColor: 'rgba(0, 123, 255, 1)',
                    borderWidth: 2,
                    tension: 0.3,
                    pointRadius: 3,
                    pointBackgroundColor: 'rgba(0, 123, 255, 1)'
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                tooltip: {
                    mode: 'index',
                    intersect: false
                },
                legend: {
                    position: 'top',
                },
                title: {
                    display: true,
                    text: 'Salinity and EC Trends'
                }
            },
            scales: {
                x: {
                    grid: {
                        display: false
                    }
                },
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Measurement Value'
                    }
                }
            }
        }
    });
}

/**
 * Initialize the salinity map using Leaflet.js
 */
function initSalinityMap() {
    // Check if we have valid readings with GPS data
    if (!readingsData || readingsData.length === 0) {
        document.getElementById('salinity-map').innerHTML = '<div class="alert alert-info">No GPS data available for mapping</div>';
        return;
    }
    
    // Initialize map
    const map = L.map('salinity-map');
    
    // Add OpenStreetMap tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);
    
    // Process the readings for mapping
    const validReadings = readingsData.filter(reading => 
        reading.latitude && reading.longitude && 
        !isNaN(parseFloat(reading.latitude)) && 
        !isNaN(parseFloat(reading.longitude))
    );
    
    if (validReadings.length === 0) {
        document.getElementById('salinity-map').innerHTML = '<div class="alert alert-info">No valid GPS coordinates found in readings</div>';
        return;
    }
    
    // Add markers for each reading location
    const markers = [];
    const markerLayer = L.layerGroup().addTo(map);
    
    validReadings.forEach(reading => {
        const lat = parseFloat(reading.latitude);
        const lng = parseFloat(reading.longitude);
        const salinity = parseFloat(reading.salinity_ppt);
        
        // Determine marker color based on salinity level
        let markerClass = 'salinity-medium';
        if (salinity < 10) {
            markerClass = 'salinity-low';
        } else if (salinity > 30) {
            markerClass = 'salinity-high';
        }
        
        // Create custom icon
        const icon = L.divIcon({
            className: markerClass,
            iconSize: [15, 15]
        });
        
        // Create marker with popup
        const marker = L.marker([lat, lng], {icon: icon}).addTo(markerLayer);
        
        // Add popup with reading details
        const popupContent = `
            <h5>Reading Details</h5>
            <p><strong>Device:</strong> ${reading.device_name}</p>
            <p><strong>Time:</strong> ${moment(reading.reading_time).format('YYYY-MM-DD HH:mm')}</p>
            <p><strong>Salinity:</strong> ${reading.salinity_ppt.toFixed(3)} ppt</p>
            <p><strong>EC Value:</strong> ${reading.ec_value.toFixed(1)} µS/cm</p>
            <p><strong>Temperature:</strong> ${reading.temperature.toFixed(1)} °C</p>
            <p><strong>Location:</strong> ${lat.toFixed(6)}, ${lng.toFixed(6)}</p>
        `;
        
        marker.bindPopup(popupContent);
        markers.push([lat, lng]);
    });
    
    // Fit map bounds to include all markers
    if (markers.length > 0) {
        map.fitBounds(markers);
    }
}

/**
 * Set up event listeners for interactive elements
 */
function initEventListeners() {
    // Refresh button
    document.getElementById('refresh-btn').addEventListener('click', function() {
        location.reload();
    });
    
    // Device detail buttons
    document.querySelectorAll('.view-device-btn').forEach(button => {
        button.addEventListener('click', function() {
            const deviceId = this.getAttribute('data-device-id');
            showDeviceDetails(deviceId);
        });
    });
    
    // Species detail buttons
    document.querySelectorAll('.view-species-btn').forEach(button => {
        button.addEventListener('click', function() {
            const speciesId = this.getAttribute('data-species-id');
            showSpeciesDetails(speciesId);
        });
    });
}

/**
 * Show device details in modal
 * @param {string} deviceId - The device ID to show details for
 */
function showDeviceDetails(deviceId) {
    // Find device in data
    const device = devicesData.find(d => d.device_id === deviceId);
    
    if (!device) {
        document.getElementById('device-details-content').innerHTML = '<div class="alert alert-warning">Device not found</div>';
        return;
    }
    
    // Get readings for this device
    const deviceReadings = readingsData.filter(r => r.device_id === deviceId);
    
    // Create content
    let content = `
        <h4>${device.name}</h4>
        <p><strong>Device ID:</strong> ${device.device_id}</p>
        <p><strong>Status:</strong> <span class="badge ${
            device.status === 'active' ? 'bg-success' : 
            (device.status === 'inactive' ? 'bg-secondary' : 'bg-warning')
        }">${device.status}</span></p>
        <p><strong>Last Seen:</strong> ${device.last_seen ? moment(device.last_seen).format('YYYY-MM-DD HH:mm:ss') : 'Never'}</p>
        
        <h5 class="mt-4">Recent Readings</h5>
    `;
    
    if (deviceReadings.length > 0) {
        content += `
            <div class="table-responsive">
                <table class="table table-sm">
                    <thead>
                        <tr>
                            <th>Time</th>
                            <th>Salinity (ppt)</th>
                            <th>EC (µS/cm)</th>
                            <th>Temperature (°C)</th>
                        </tr>
                    </thead>
                    <tbody>
        `;
        
        // Add up to 10 most recent readings
        deviceReadings.slice(0, 10).forEach(reading => {
            content += `
                <tr>
                    <td>${moment(reading.reading_time).format('MM/DD HH:mm')}</td>
                    <td>${parseFloat(reading.salinity_ppt).toFixed(3)}</td>
                    <td>${parseFloat(reading.ec_value).toFixed(1)}</td>
                    <td>${parseFloat(reading.temperature).toFixed(1)}</td>
                </tr>
            `;
        });
        
        content += `
                    </tbody>
                </table>
            </div>
        `;
    } else {
        content += '<p>No readings available for this device</p>';
    }
    
    // Update modal
    document.getElementById('device-details-content').innerHTML = content;
    document.getElementById('device-modal-label').textContent = `Device: ${device.name}`;
    
    // Show modal
    const deviceModal = new bootstrap.Modal(document.getElementById('device-modal'));
    deviceModal.show();
}

/**
 * Show species details in modal
 * @param {number} speciesId - The species ID to show details for
 */
function showSpeciesDetails(speciesId) {
    // Find species in data
    const species = speciesData.find(s => parseInt(s.id) === parseInt(speciesId));
    
    if (!species) {
        document.getElementById('species-details-content').innerHTML = '<div class="alert alert-warning">Species not found</div>';
        return;
    }
    
    // Create content
    let content = `
        <h4>${species.common_name}</h4>
        <p class="text-muted fst-italic">${species.scientific_name}</p>
        
        <h5 class="mt-3">Salinity Tolerance</h5>
        <p><strong>Minimum:</strong> ${species.min_salinity} ppt</p>
        <p><strong>Ideal:</strong> ${species.ideal_salinity} ppt</p>
        <p><strong>Maximum:</strong> ${species.max_salinity} ppt</p>
        
        <div class="salinity-range-wrapper mt-3">
            <div class="progress" style="height: 25px;">
                <div class="progress-bar bg-light" role="progressbar" 
                    style="width: ${(species.min_salinity / 45) * 100}%">
                </div>
                <div class="progress-bar bg-success position-relative" role="progressbar" 
                    style="width: ${((species.max_salinity - species.min_salinity) / 45) * 100}%">
                    <div class="ideal-marker" style="left: ${((species.ideal_salinity - species.min_salinity) / (species.max_salinity - species.min_salinity)) * 100}%"></div>
                </div>
            </div>
            <div class="d-flex justify-content-between mt-1">
                <small>${species.min_salinity} ppt</small>
                <small>Ideal: ${species.ideal_salinity} ppt</small>
                <small>${species.max_salinity} ppt</small>
            </div>
        </div>
        
        <h5 class="mt-4">Planting Recommendations</h5>
        <p>This species is suitable for coastal areas with salinity levels between ${species.min_salinity} and ${species.max_salinity} ppt.</p>
        <p>For optimal growth, aim for areas with salinity around ${species.ideal_salinity} ppt.</p>
    `;
    
    // Update modal
    document.getElementById('species-details-content').innerHTML = content;
    document.getElementById('species-modal-label').textContent = `Mangrove Species: ${species.common_name}`;
    
    // Show modal
    const speciesModal = new bootstrap.Modal(document.getElementById('species-modal'));
    speciesModal.show();
}

/**
 * Update the last updated time display
 */
function updateLastUpdatedTime() {
    document.getElementById('last-updated').textContent = moment().format('HH:mm:ss');
}
