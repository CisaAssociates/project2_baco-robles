-- Salinity Monitoring Device Database Schema
-- For Mangrove Planting Variety Recommendation System

-- Create database
CREATE DATABASE IF NOT EXISTS salinity_iot_db;
USE salinity_iot_db;

-- Users table for authentication
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    role ENUM('admin', 'researcher', 'field_worker') NOT NULL DEFAULT 'field_worker',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Devices table to track IoT devices
CREATE TABLE IF NOT EXISTS devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    status ENUM('active', 'inactive', 'maintenance') NOT NULL DEFAULT 'active',
    last_seen TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Arduino data table for raw sensor readings
CREATE TABLE IF NOT EXISTS arduino_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    raw_data TEXT NOT NULL,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- EC sensor data for processed electrical conductivity readings
CREATE TABLE IF NOT EXISTS ec_sensor_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    ec_value FLOAT NOT NULL COMMENT 'Electrical conductivity in µS/cm',
    salinity_ppt FLOAT NOT NULL COMMENT 'Salinity in parts per thousand',
    temperature FLOAT NOT NULL COMMENT 'Temperature in Celsius',
    reading_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- GPS data for location tracking
CREATE TABLE IF NOT EXISTS gps_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    altitude FLOAT DEFAULT NULL,
    accuracy FLOAT DEFAULT NULL,
    reading_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- Mangrove species table for recommendations
CREATE TABLE IF NOT EXISTS mangrove_species (
    id INT AUTO_INCREMENT PRIMARY KEY,
    scientific_name VARCHAR(100) NOT NULL,
    common_name VARCHAR(100) NOT NULL,
    min_salinity FLOAT NOT NULL COMMENT 'Minimum salinity tolerance (ppt)',
    max_salinity FLOAT NOT NULL COMMENT 'Maximum salinity tolerance (ppt)',
    ideal_salinity FLOAT NOT NULL COMMENT 'Ideal salinity range (ppt)',
    description TEXT,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Readings table to link EC and GPS data
CREATE TABLE IF NOT EXISTS readings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    ec_data_id INT NOT NULL,
    gps_data_id INT NOT NULL,
    reading_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    FOREIGN KEY (ec_data_id) REFERENCES ec_sensor_data(id),
    FOREIGN KEY (gps_data_id) REFERENCES gps_data(id)
);

-- Settings table for device configuration
CREATE TABLE IF NOT EXISTS settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    setting_key VARCHAR(50) NOT NULL,
    setting_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    UNIQUE KEY unique_setting (device_id, setting_key)
);

-- System log table for events and errors
CREATE TABLE IF NOT EXISTS system_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) DEFAULT NULL,
    log_level ENUM('info', 'warning', 'error', 'critical') NOT NULL,
    message TEXT NOT NULL,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE SET NULL
);

-- RS485 data table (if RS485 protocol is integrated)
CREATE TABLE IF NOT EXISTS rs485_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    direction ENUM('in', 'out') NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- Recommendations table for storing mangrove variety suggestions based on readings
CREATE TABLE IF NOT EXISTS recommendations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reading_id INT NOT NULL,
    species_id INT NOT NULL,
    confidence FLOAT NOT NULL COMMENT 'Confidence score (0-1)',
    recommendation_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reading_id) REFERENCES readings(id),
    FOREIGN KEY (species_id) REFERENCES mangrove_species(id)
);

-- Insert some default mangrove species data
INSERT INTO mangrove_species (scientific_name, common_name, min_salinity, max_salinity, ideal_salinity, description)
VALUES
    ('Rhizophora mucronata', 'Red Mangrove', 10, 35, 25, 'Highly salt-tolerant species with prominent aerial roots'),
    ('Avicennia marina', 'Grey Mangrove', 5, 30, 18, 'Hardy species with pneumatophores that can tolerate high salinity'),
    ('Sonneratia alba', 'Mangrove Apple', 15, 40, 30, 'Found in areas with high salinity levels, produces apple-like fruits'),
    ('Bruguiera gymnorrhiza', 'Large-leafed Mangrove', 8, 25, 15, 'Prefers moderate salinity, has knee-like roots'),
    ('Ceriops tagal', 'Yellow Mangrove', 12, 32, 22, 'Tolerates high salinity, has viviparous seeds'),
    ('Aegiceras corniculatum', 'River Mangrove', 2, 20, 10, 'Low salinity tolerance, found in more brackish zones'),
    ('Lumnitzera racemosa', 'Black Mangrove', 7, 28, 17, 'Moderate salinity tolerance, has black bark'),
    ('Xylocarpus granatum', 'Cannonball Mangrove', 5, 22, 15, 'Moderate salinity tolerance, produces large round fruits');

-- Insert admin user (password: admin123)
INSERT INTO users (username, password, email, role)
VALUES ('admin', '$2y$10$8JfS.HnCB8qXvIl3SfyQpO6UqFwQvY53.V5zYi28XBpg0sz.8g2ym', 'admin@example.com', 'admin');
