-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 02, 2025 at 04:47 PM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `salinity_iot_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `arduino_data`
--

CREATE TABLE `arduino_data` (
  `id` int NOT NULL,
  `device_id` varchar(50) NOT NULL,
  `raw_data` text NOT NULL,
  `received_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `arduino_data`
--

INSERT INTO `arduino_data` (`id`, `device_id`, `raw_data`, `received_at`) VALUES
(8, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":40.32258,\"salinity_ppt\":0.020161,\"temperature\":25,\"latitude\":10.35747467,\"longitude\":124.9651112}', '2025-05-31 00:33:58'),
(9, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":44.51613,\"salinity_ppt\":0.022258,\"temperature\":25,\"latitude\":10.35747917,\"longitude\":124.9651368}', '2025-05-31 00:38:58'),
(10, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":22.25807,\"salinity_ppt\":0.011129,\"temperature\":25,\"latitude\":10.35750317,\"longitude\":124.9651788}', '2025-05-31 00:43:58'),
(11, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":44.83871,\"salinity_ppt\":0.022419,\"temperature\":25,\"latitude\":10.35751467,\"longitude\":124.9651657}', '2025-05-31 00:48:58'),
(12, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":18.70968,\"salinity_ppt\":0.009355,\"temperature\":25,\"latitude\":10.35753617,\"longitude\":124.9651037}', '2025-05-31 00:53:58'),
(13, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":44.19355,\"salinity_ppt\":0.022097,\"temperature\":25,\"latitude\":10.35751583,\"longitude\":124.9651202}', '2025-05-31 00:58:58'),
(14, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":44.51613,\"salinity_ppt\":0.022258,\"temperature\":25,\"latitude\":10.357475,\"longitude\":124.9651865}', '2025-05-31 01:03:58'),
(15, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":45.80645,\"salinity_ppt\":0.022903,\"temperature\":25,\"latitude\":10.35750383,\"longitude\":124.9651268}', '2025-05-31 01:08:58'),
(16, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":44.51613,\"salinity_ppt\":0.022258,\"temperature\":25,\"latitude\":10.357506,\"longitude\":124.9652635}', '2025-05-31 01:13:58'),
(17, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":41.29033,\"salinity_ppt\":0.020645,\"temperature\":25,\"latitude\":10.3575425,\"longitude\":124.9652313}', '2025-05-31 01:18:58'),
(18, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":44.51613,\"salinity_ppt\":0.022258,\"temperature\":25,\"latitude\":10.3575055,\"longitude\":124.9652135}', '2025-05-31 01:23:58'),
(19, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":41.29033,\"salinity_ppt\":0.020645,\"temperature\":25,\"latitude\":10.35747233,\"longitude\":124.9651983}', '2025-05-31 01:28:58'),
(20, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":36.77419,\"salinity_ppt\":0.018387,\"temperature\":25}', '2025-06-02 02:17:00'),
(21, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":17.41936,\"salinity_ppt\":0.00871,\"temperature\":25}', '2025-06-02 02:22:00'),
(22, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":28.3871,\"salinity_ppt\":0.014194,\"temperature\":25}', '2025-06-02 02:33:20'),
(23, 'SAL001', '{\"device_id\":\"SAL001\",\"ec_value\":44.51613,\"salinity_ppt\":0.022258,\"temperature\":25,\"latitude\":10.35730033,\"longitude\":124.9648865}', '2025-06-02 02:46:30');

-- --------------------------------------------------------

--
-- Table structure for table `devices`
--

CREATE TABLE `devices` (
  `id` int NOT NULL,
  `device_id` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text,
  `status` enum('active','inactive','maintenance') NOT NULL DEFAULT 'active',
  `last_seen` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

--
-- Dumping data for table `devices`
--

INSERT INTO `devices` (`id`, `device_id`, `name`, `description`, `status`, `last_seen`, `created_at`, `updated_at`) VALUES
(1, 'SAL001', 'Device SAL001', 'Auto-registered device', 'active', '2025-06-02 02:46:30', '2025-05-30 23:25:02', '2025-06-02 02:46:30');

-- --------------------------------------------------------

--
-- Table structure for table `ec_sensor_data`
--

CREATE TABLE `ec_sensor_data` (
  `id` int NOT NULL,
  `device_id` varchar(50) NOT NULL,
  `ec_value` float NOT NULL COMMENT 'Electrical conductivity in µS/cm',
  `salinity_ppt` float NOT NULL COMMENT 'Salinity in parts per thousand',
  `temperature` float NOT NULL COMMENT 'Temperature in Celsius',
  `reading_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `ec_sensor_data`
--

INSERT INTO `ec_sensor_data` (`id`, `device_id`, `ec_value`, `salinity_ppt`, `temperature`, `reading_time`) VALUES
(8, 'SAL001', 40.3226, 0.020161, 25, '2025-05-31 00:33:58'),
(9, 'SAL001', 44.5161, 0.022258, 25, '2025-05-31 00:38:58'),
(10, 'SAL001', 22.2581, 0.011129, 25, '2025-05-31 00:43:58'),
(11, 'SAL001', 44.8387, 0.022419, 25, '2025-05-31 00:48:58'),
(12, 'SAL001', 18.7097, 0.009355, 25, '2025-05-31 00:53:58'),
(13, 'SAL001', 44.1936, 0.022097, 25, '2025-05-31 00:58:58'),
(14, 'SAL001', 44.5161, 0.022258, 25, '2025-05-31 01:03:58'),
(15, 'SAL001', 45.8064, 0.022903, 25, '2025-05-31 01:08:58'),
(16, 'SAL001', 44.5161, 0.022258, 25, '2025-05-31 01:13:58'),
(17, 'SAL001', 41.2903, 0.020645, 25, '2025-05-31 01:18:58'),
(18, 'SAL001', 44.5161, 0.022258, 25, '2025-05-31 01:23:58'),
(19, 'SAL001', 41.2903, 0.020645, 25, '2025-05-31 01:28:58'),
(20, 'SAL001', 36.7742, 0.018387, 25, '2025-06-02 02:17:00'),
(21, 'SAL001', 17.4194, 0.00871, 25, '2025-06-02 02:22:00'),
(22, 'SAL001', 28.3871, 0.014194, 25, '2025-06-02 02:33:20'),
(23, 'SAL001', 44.5161, 0.022258, 25, '2025-06-02 02:46:30');

-- --------------------------------------------------------

--
-- Table structure for table `gps_data`
--

CREATE TABLE `gps_data` (
  `id` int NOT NULL,
  `device_id` varchar(50) NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `altitude` float DEFAULT NULL,
  `accuracy` float DEFAULT NULL,
  `reading_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `gps_data`
--

INSERT INTO `gps_data` (`id`, `device_id`, `latitude`, `longitude`, `altitude`, `accuracy`, `reading_time`) VALUES
(4, 'SAL001', '10.35747467', '124.96511120', NULL, NULL, '2025-05-31 00:33:58'),
(5, 'SAL001', '10.35747917', '124.96513680', NULL, NULL, '2025-05-31 00:38:58'),
(6, 'SAL001', '10.35750317', '124.96517880', NULL, NULL, '2025-05-31 00:43:58'),
(7, 'SAL001', '10.35751467', '124.96516570', NULL, NULL, '2025-05-31 00:48:58'),
(8, 'SAL001', '10.35753617', '124.96510370', NULL, NULL, '2025-05-31 00:53:58'),
(9, 'SAL001', '10.35751583', '124.96512020', NULL, NULL, '2025-05-31 00:58:58'),
(10, 'SAL001', '10.35747500', '124.96518650', NULL, NULL, '2025-05-31 01:03:58'),
(11, 'SAL001', '10.35750383', '124.96512680', NULL, NULL, '2025-05-31 01:08:58'),
(12, 'SAL001', '10.35750600', '124.96526350', NULL, NULL, '2025-05-31 01:13:58'),
(13, 'SAL001', '10.35754250', '124.96523130', NULL, NULL, '2025-05-31 01:18:58'),
(14, 'SAL001', '10.35750550', '124.96521350', NULL, NULL, '2025-05-31 01:23:58'),
(15, 'SAL001', '10.35747233', '124.96519830', NULL, NULL, '2025-05-31 01:28:58'),
(16, 'SAL001', '10.35730033', '124.96488650', NULL, NULL, '2025-06-02 02:46:30');

-- --------------------------------------------------------

--
-- Table structure for table `mangrove_species`
--

CREATE TABLE `mangrove_species` (
  `id` int NOT NULL,
  `scientific_name` varchar(100) NOT NULL,
  `common_name` varchar(100) NOT NULL,
  `min_salinity` float NOT NULL COMMENT 'Minimum salinity tolerance (ppt)',
  `max_salinity` float NOT NULL COMMENT 'Maximum salinity tolerance (ppt)',
  `ideal_salinity` float NOT NULL COMMENT 'Ideal salinity range (ppt)',
  `description` text,
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

--
-- Dumping data for table `mangrove_species`
--

INSERT INTO `mangrove_species` (`id`, `scientific_name`, `common_name`, `min_salinity`, `max_salinity`, `ideal_salinity`, `description`, `image_url`, `created_at`, `updated_at`) VALUES
(1, 'Rhizophora mucronata', 'Red Mangrove', 10, 35, 25, 'Highly salt-tolerant species with prominent aerial roots', NULL, '2025-05-30 22:06:20', '2025-05-30 22:06:20'),
(2, 'Avicennia marina', 'Grey Mangrove', 5, 30, 18, 'Hardy species with pneumatophores that can tolerate high salinity', NULL, '2025-05-30 22:06:20', '2025-05-30 22:06:20'),
(3, 'Sonneratia alba', 'Mangrove Apple', 15, 40, 30, 'Found in areas with high salinity levels, produces apple-like fruits', NULL, '2025-05-30 22:06:20', '2025-05-30 22:06:20'),
(4, 'Bruguiera gymnorrhiza', 'Large-leafed Mangrove', 8, 25, 15, 'Prefers moderate salinity, has knee-like roots', NULL, '2025-05-30 22:06:20', '2025-05-30 22:06:20'),
(5, 'Ceriops tagal', 'Yellow Mangrove', 12, 32, 22, 'Tolerates high salinity, has viviparous seeds', NULL, '2025-05-30 22:06:20', '2025-05-30 22:06:20'),
(6, 'Aegiceras corniculatum', 'River Mangrove', 2, 20, 10, 'Low salinity tolerance, found in more brackish zones', NULL, '2025-05-30 22:06:20', '2025-05-30 22:06:20'),
(7, 'Lumnitzera racemosa', 'Black Mangrove', 7, 28, 17, 'Moderate salinity tolerance, has black bark', NULL, '2025-05-30 22:06:20', '2025-05-30 22:06:20'),
(8, 'Xylocarpus granatum', 'Cannonball Mangrove', 5, 22, 15, 'Moderate salinity tolerance, produces large round fruits', NULL, '2025-05-30 22:06:20', '2025-05-30 22:06:20');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `token` varchar(64) NOT NULL,
  `expires_at` timestamp NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------

--
-- Table structure for table `readings`
--

CREATE TABLE `readings` (
  `id` int NOT NULL,
  `device_id` varchar(50) NOT NULL,
  `ec_data_id` int NOT NULL,
  `gps_data_id` int NOT NULL,
  `reading_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` text
);

--
-- Dumping data for table `readings`
--

INSERT INTO `readings` (`id`, `device_id`, `ec_data_id`, `gps_data_id`, `reading_time`, `notes`) VALUES
(4, 'SAL001', 8, 4, '2025-05-31 00:33:58', NULL),
(5, 'SAL001', 9, 5, '2025-05-31 00:38:58', NULL),
(6, 'SAL001', 10, 6, '2025-05-31 00:43:58', NULL),
(7, 'SAL001', 11, 7, '2025-05-31 00:48:58', NULL),
(8, 'SAL001', 12, 8, '2025-05-31 00:53:58', NULL),
(9, 'SAL001', 13, 9, '2025-05-31 00:58:58', NULL),
(10, 'SAL001', 14, 10, '2025-05-31 01:03:58', NULL),
(11, 'SAL001', 15, 11, '2025-05-31 01:08:58', NULL),
(12, 'SAL001', 16, 12, '2025-05-31 01:13:58', NULL),
(13, 'SAL001', 17, 13, '2025-05-31 01:18:58', NULL),
(14, 'SAL001', 18, 14, '2025-05-31 01:23:58', NULL),
(15, 'SAL001', 19, 15, '2025-05-31 01:28:58', NULL),
(16, 'SAL001', 23, 16, '2025-06-02 02:46:30', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `recommendations`
--

CREATE TABLE `recommendations` (
  `id` int NOT NULL,
  `reading_id` int NOT NULL,
  `species_id` int NOT NULL,
  `confidence` float NOT NULL COMMENT 'Confidence score (0-1)',
  `recommendation_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------

--
-- Table structure for table `rs485_data`
--

CREATE TABLE `rs485_data` (
  `id` int NOT NULL,
  `device_id` varchar(50) NOT NULL,
  `message` text NOT NULL,
  `direction` enum('in','out') NOT NULL,
  `timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `id` int NOT NULL,
  `device_id` varchar(50) NOT NULL,
  `setting_key` varchar(50) NOT NULL,
  `setting_value` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- --------------------------------------------------------

--
-- Table structure for table `system_log`
--

CREATE TABLE `system_log` (
  `id` int NOT NULL,
  `device_id` varchar(50) DEFAULT NULL,
  `log_level` enum('info','warning','error','critical') NOT NULL,
  `message` text NOT NULL,
  `log_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `system_log`
--

INSERT INTO `system_log` (`id`, `device_id`, `log_level`, `message`, `log_time`) VALUES
(9, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 00:33:58'),
(10, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 00:38:58'),
(11, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 00:43:58'),
(12, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 00:48:58'),
(13, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 00:53:58'),
(14, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 00:58:58'),
(15, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 01:03:58'),
(16, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 01:08:58'),
(17, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 01:13:58'),
(18, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 01:18:58'),
(19, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 01:23:58'),
(20, 'SAL001', 'info', 'Data received from device: SAL001', '2025-05-31 01:28:58'),
(21, 'SAL001', 'info', 'Data received from device: SAL001', '2025-06-02 02:17:00'),
(22, 'SAL001', 'info', 'Data received from device: SAL001', '2025-06-02 02:22:00'),
(23, 'SAL001', 'info', 'Data received from device: SAL001', '2025-06-02 02:33:20'),
(24, 'SAL001', 'info', 'Data received from device: SAL001', '2025-06-02 02:46:30');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `role` enum('admin','researcher','field_worker') NOT NULL DEFAULT 'field_worker',
  `last_login` timestamp NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `email`, `role`, `last_login`, `created_at`, `updated_at`) VALUES
(1, 'admin', '$2y$10$vdmnQxtAxCMayN5iuCvYvuXunEC9nJtdOwn2YMOzrlSGwqQltOfC.', 'admin@example.com', 'admin', '2025-06-02 01:41:45', '2025-05-30 22:06:20', '2025-06-02 01:41:45');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `arduino_data`
--
ALTER TABLE `arduino_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `device_id` (`device_id`);

--
-- Indexes for table `devices`
--
ALTER TABLE `devices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `device_id` (`device_id`);

--
-- Indexes for table `ec_sensor_data`
--
ALTER TABLE `ec_sensor_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `device_id` (`device_id`);

--
-- Indexes for table `gps_data`
--
ALTER TABLE `gps_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `device_id` (`device_id`);

--
-- Indexes for table `mangrove_species`
--
ALTER TABLE `mangrove_species`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `readings`
--
ALTER TABLE `readings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `device_id` (`device_id`),
  ADD KEY `ec_data_id` (`ec_data_id`),
  ADD KEY `gps_data_id` (`gps_data_id`);

--
-- Indexes for table `recommendations`
--
ALTER TABLE `recommendations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reading_id` (`reading_id`),
  ADD KEY `species_id` (`species_id`);

--
-- Indexes for table `rs485_data`
--
ALTER TABLE `rs485_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `device_id` (`device_id`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_setting` (`device_id`,`setting_key`);

--
-- Indexes for table `system_log`
--
ALTER TABLE `system_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `device_id` (`device_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `arduino_data`
--
ALTER TABLE `arduino_data`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `devices`
--
ALTER TABLE `devices`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `ec_sensor_data`
--
ALTER TABLE `ec_sensor_data`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `gps_data`
--
ALTER TABLE `gps_data`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `mangrove_species`
--
ALTER TABLE `mangrove_species`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `readings`
--
ALTER TABLE `readings`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `recommendations`
--
ALTER TABLE `recommendations`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rs485_data`
--
ALTER TABLE `rs485_data`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `settings`
--
ALTER TABLE `settings`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `system_log`
--
ALTER TABLE `system_log`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `arduino_data`
--
ALTER TABLE `arduino_data`
  ADD CONSTRAINT `arduino_data_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE;

--
-- Constraints for table `ec_sensor_data`
--
ALTER TABLE `ec_sensor_data`
  ADD CONSTRAINT `ec_sensor_data_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE;

--
-- Constraints for table `gps_data`
--
ALTER TABLE `gps_data`
  ADD CONSTRAINT `gps_data_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE;

--
-- Constraints for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `readings`
--
ALTER TABLE `readings`
  ADD CONSTRAINT `readings_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `readings_ibfk_2` FOREIGN KEY (`ec_data_id`) REFERENCES `ec_sensor_data` (`id`),
  ADD CONSTRAINT `readings_ibfk_3` FOREIGN KEY (`gps_data_id`) REFERENCES `gps_data` (`id`);

--
-- Constraints for table `recommendations`
--
ALTER TABLE `recommendations`
  ADD CONSTRAINT `recommendations_ibfk_1` FOREIGN KEY (`reading_id`) REFERENCES `readings` (`id`),
  ADD CONSTRAINT `recommendations_ibfk_2` FOREIGN KEY (`species_id`) REFERENCES `mangrove_species` (`id`);

--
-- Constraints for table `rs485_data`
--
ALTER TABLE `rs485_data`
  ADD CONSTRAINT `rs485_data_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE;

--
-- Constraints for table `settings`
--
ALTER TABLE `settings`
  ADD CONSTRAINT `settings_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE;

--
-- Constraints for table `system_log`
--
ALTER TABLE `system_log`
  ADD CONSTRAINT `system_log_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
