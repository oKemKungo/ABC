<?php
// Function to handle the admin dashboard page
function handleAdminDashboard($conn) { // Added $conn parameter
    if (!isLoggedIn() || !isAdmin()) {
        redirectTo('?page=login');
    }
    renderHeader("Admin Dashboard");
    echo "<div class='container'>"; // Start .container
    echo "<h1>Admin Dashboard</h1>";
    echo "<p>ยินดีต้อนรับผู้ดูแลระบบ!</p>";
    echo "<ul>";
    echo "<li><a href='?page=admin_manage_rooms'>จัดการห้องพัก</a></li>";
    echo "<li><a href='?page=admin_manage_bookings'>จัดการการจอง</a></li>";
    echo "</ul>";
    echo "</div>"; // Close .container
    renderFooter();
}
?>