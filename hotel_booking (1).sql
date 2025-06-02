-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 02, 2025 at 06:04 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hotel_booking`
--

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `booking_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `check_in_date` date NOT NULL,
  `check_out_date` date NOT NULL,
  `guest_name` varchar(255) NOT NULL,
  `guest_email` varchar(255) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `booking_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('pending','confirmed','cancelled','completed') NOT NULL DEFAULT 'pending',
  `num_guests` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`booking_id`, `user_id`, `room_id`, `check_in_date`, `check_out_date`, `guest_name`, `guest_email`, `total_price`, `booking_date`, `status`, `num_guests`) VALUES
(8, 4, 8, '2025-05-29', '2025-05-30', 'kemdd', 'kemdd2d@gmail.com', 100.00, '2025-05-29 07:11:13', 'cancelled', 1),
(11, 8, 1, '2025-05-29', '2025-05-30', 'kemnaja', 'kemnaja@gmail.com', 1500.00, '2025-05-29 08:29:53', 'cancelled', 1);

-- --------------------------------------------------------

--
-- Table structure for table `rooms`
--

CREATE TABLE `rooms` (
  `room_id` int(11) NOT NULL,
  `room_number` varchar(50) NOT NULL,
  `room_type` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `price_per_night` decimal(10,2) NOT NULL,
  `capacity` int(11) NOT NULL,
  `image_url` varchar(255) DEFAULT 'https://via.placeholder.com/300x200?text=Room+Image',
  `is_available` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rooms`
--

INSERT INTO `rooms` (`room_id`, `room_number`, `room_type`, `description`, `price_per_night`, `capacity`, `image_url`, `is_available`) VALUES
(1, '101', 'Standard Room', 'ห้องพักมาตรฐาน พร้อมสิ่งอำนวยความสะดวกครบครัน', 1500.00, 3, 'images/hotel2.jpg', 1),
(2, '102', 'Standard Room', 'ห้องพักมาตรฐาน วิวเมือง', 1600.00, 2, 'images/hotel3.jpg', 1),
(3, '201', 'Deluxe Room', 'ห้องดีลักซ์กว้างขวาง พร้อมระเบียงส่วนตัว', 2500.00, 3, 'images/hotel4.jpg', 1),
(4, '202', 'Deluxe Room', 'ห้องดีลักซ์พร้อมวิวสระว่ายน้ำ', 2700.00, 3, 'images/hotel5.jpg', 1),
(5, '301', 'Suite', 'ห้องสวีทสุดหรู พร้อมห้องนั่งเล่นแยกส่วน', 4000.00, 4, 'images/hotel6.jpg', 1),
(6, '302', 'Family Room', 'ห้องพักสำหรับครอบครัวขนาดใหญ่', 3500.00, 5, 'images/hotel7.jpg', 1),
(8, '', 'ระดับโลก', '12345', 100.00, 100, 'images/hotel4.jpg', 1);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('guest','admin') NOT NULL DEFAULT 'guest',
  `registration_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `email`, `password`, `role`, `registration_date`) VALUES
(1, 'kemza', 'kemza@gmail.com', '$2y$10$mPWmTRR1DLCYVSDGBDTD9.r/RbSa/jUygJocNnhwGqHxI6.SyvE5K', 'guest', '2025-05-29 01:05:19'),
(2, 'kemzdd', 'kemdd@gmail.com', '$2y$10$zayyydpkSLUDpu5YhzCSreHRqThrU7s5ySorAXgYiJ6VfFHkAnRl.', 'guest', '2025-05-29 01:07:33'),
(3, 'kemddd', 'kemddd@gmail.com', '$2y$10$kx16gV7.UOiIOB66k7y3GezqZM6cN1ZcmtRYbDvYugMcRAsFNklbm', 'guest', '2025-05-29 01:08:20'),
(4, 'kemdd', 'kemdd2d@gmail.com', '$2y$10$IvdTHx15gBOQTv7EAx8tjuCPziLl6YUisKhP6AcIEgJdwC20kno5y', 'admin', '2025-05-29 01:21:25'),
(5, 'kemdd55', 'kemdd255d@gmail.com', '$2y$10$nlT33vcsBMV/SPNfjHRkbeyAaTT7skhkTXLOOY5UMOqWeBkJidHcm', '', '2025-05-29 03:51:10'),
(6, 'kem555', 'kem5555@gmail.com', '$2y$10$4.NWWpWkn.muRxeepLoQBOUZDceATlaTmcbU.VI5VAwRPcHwlC77K', '', '2025-05-29 06:42:21'),
(7, 'kem5554', 'kem55554@gmail.com', '$2y$10$lLsef2MTqQeuWxbD3NacxeG/b6cRka6JHlCIdkzPuiJQ500tyqI..', '', '2025-05-29 08:28:37'),
(8, 'kemnaja', 'kemnaja@gmail.com', '$2y$10$dK6J8g0vN1PlpceMgwG4tevI7LU9Xtmv/9kB0MbsL/txXSN3aENmW', '', '2025-05-29 08:29:26'),
(9, 'new', 'new154154454545@gmail.com', '$2y$10$ssy0ov2eVyMDsZylKGS8QuA2/938jis3Ty.larAuonfaxvZnZbIrS', '', '2025-05-29 09:02:09');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`booking_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `room_id` (`room_id`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`room_id`),
  ADD UNIQUE KEY `room_number` (`room_number`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `booking_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
