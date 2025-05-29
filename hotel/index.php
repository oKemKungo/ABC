<?php

session_start();


require_once 'config.php';


require_once 'layout.php';

// ตรวจสอบการเชื่อมต่อฐานข้อมูล
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");

// --- Page Routing Logic ---
$page = $_GET['page'] ?? 'home'; // Default page is 'home'

// --- REDIRECT LOGIC: **สำคัญมาก: ต้องอยู่ตรงนี้ ก่อนที่จะมีการเรียก renderHeader() หรือ echo ใดๆ** ---
// ตรวจสอบการเข้าถึงหน้าสำหรับผู้ดูแลระบบ
if (in_array($page, ['admin_dashboard', 'admin_manage_rooms', 'admin_manage_bookings', 'admin_edit_room'])) { // เพิ่ม admin_edit_room
    if (!isLoggedIn() || !isAdmin()) {
        $_SESSION['redirect_after_login'] = $_SERVER['REQUEST_URI']; // เก็บ URL ปัจจุบัน
        redirectTo('?page=login'); // redirectTo จะมี exit() อยู่ภายใน
    }
}

// ตรวจสอบผู้ใช้ที่ล็อกอินอยู่แล้วพยายามเข้าหน้า login หรือ register
if (in_array($page, ['login', 'register'])) {
    if (isLoggedIn()) {
        redirectTo('?page=home'); // redirectTo จะมี exit() อยู่ภายใน
    }
}

// --- Page Handlers ---
// Inclusion of individual page files based on the requested page
switch ($page) {
    case 'home':
        require_once 'pages/home.php';
        handleHome($conn);
        break;
    case 'rooms':
        require_once 'pages/rooms.php';
        handleRooms($conn);
        break;
    case 'book':
        require_once 'pages/book.php';
        handleBook($conn);
        break;
    case 'confirm':
        require_once 'pages/confirm.php';
        handleConfirm($conn);
        break;
    case 'login':
        require_once 'pages/login.php';
        handleLogin($conn);
        break;
    case 'register':
        require_once 'pages/register.php';
        handleRegister($conn);
        break;
    case 'logout':
        // ฟังก์ชัน handleLogout อยู่ใน layout.php แล้ว
        handleLogout(); // เรียกใช้ฟังก์ชันจาก layout.php
        break;
    case 'booking_history': //
        require_once 'pages/booking_history.php'; //
        handleBookingHistory($conn); //
        break; //
    case 'cancel_booking': // **เพิ่มส่วนนี้**
        require_once 'pages/cancel_booking.php';
        handleCancelBooking($conn);
        break;
    case 'admin_dashboard':
        require_once 'pages/admin_dashboard.php';
        handleAdminDashboard($conn);
        break;
    case 'admin_manage_rooms':
        require_once 'pages/admin_manage_rooms.php';
        handleAdminManageRooms($conn);
        break;
    case 'admin_edit_room': // เพิ่ม case สำหรับหน้าแก้ไขห้องพัก
        require_once 'pages/admin_edit_room.php';
        handleAdminEditRoom($conn);
        break;
    case 'admin_manage_bookings': // เพิ่ม case สำหรับหน้าจัดการการจอง
        require_once 'pages/admin_manage_bookings.php';
        handleAdminManageBookings($conn);
        break;
    default:
        // Handle 404 or redirect to home
        redirectTo('?page=home');
        break;
}

// ไม่ต้องเรียก renderFooter() ที่นี่ เพราะแต่ละ handle page จะเรียกเอง
// $conn->close(); // ปิดการเชื่อมต่อ DB
// Note: ไม่ควรปิดการเชื่อมต่อที่นี่ ถ้ามีการเรียกใช้ $conn ใน renderFooter หรือส่วนอื่น ๆ
?>