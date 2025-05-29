<?php
// Function to handle the booking confirmation and database insertion
function handleConfirm($conn) {
    renderHeader("การจองสำเร็จ");
    echo "<div class='container'>"; // Start .container
    if (!isLoggedIn()) {
        redirectTo('?page=login');
    }

    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        $room_id = $_POST['room_id'] ?? '';
        $check_in_date = $_POST['check_in'] ?? '';
        $check_out_date = $_POST['check_out'] ?? '';
        $total_price = $_POST['total_price'] ?? 0;
        $user_id = $_POST['user_id'] ?? '';

        if (empty($room_id) || empty($check_in_date) || empty($check_out_date) || empty($user_id)) {
            echo "<p>ข้อมูลไม่ครบถ้วน กรุณากรอกข้อมูลให้ถูกต้อง</p>";
            echo "</div>"; // Close .container
            renderFooter();
            return;
        }

        // Fetch user info from DB for guest_name and guest_email if not in session, or if bookings table needs it
        $stmt_user = $conn->prepare("SELECT username, email FROM users WHERE user_id = ?");
        $stmt_user->bind_param("i", $user_id);
        $stmt_user->execute();
        $result_user = $stmt_user->get_result();
        $user_info = $result_user->fetch_assoc();
        $stmt_user->close();

        if (!$user_info) {
            echo "<p>ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่</p>";
            echo "</div>"; // Close .container
            renderFooter();
            return;
        }
        $guest_name = $user_info['username'];
        $guest_email = $user_info['email'];
        // You might need a guest_phone column in users table or make it optional in bookings

        $stmt = $conn->prepare("INSERT INTO bookings (room_id, user_id, check_in_date, check_out_date, guest_name, guest_email, total_price) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("iissssd", $room_id, $user_id, $check_in_date, $check_out_date, $guest_name, $guest_email, $total_price);

        if ($stmt->execute()) {
            $booking_id = $conn->insert_id;
            echo "<h1>การจองสำเร็จ!</h1>";
            echo "<p>รหัสการจองของคุณคือ: <strong>" . htmlspecialchars($booking_id) . "</strong></p>";
            echo "<p>เราได้ส่งอีเมลยืนยันการจองไปยัง " . htmlspecialchars($guest_email) . " เรียบร้อยแล้ว</p>";
            echo "<a href='?page=home'>กลับหน้าหลัก</a>";
        } else {
            echo "<h1>เกิดข้อผิดพลาดในการจอง</h1>";
            echo "<p>กรุณาลองใหม่อีกครั้ง หรือติดต่อผู้ดูแลระบบ</p>";
            echo "<p>Error: " . htmlspecialchars($stmt->error) . "</p>";
        }
        $stmt->close();
    } else {
        echo "<p>ไม่สามารถเข้าถึงหน้านี้โดยตรง</p>";
    }
    echo "</div>"; // Close .container
    renderFooter();
}
?>