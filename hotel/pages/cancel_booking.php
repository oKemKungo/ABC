<?php
// pages/cancel_booking.php

// ตรวจสอบว่าผู้ใช้ล็อกอินอยู่หรือไม่
if (!isLoggedIn()) {
    $_SESSION['error'] = "กรุณาเข้าสู่ระบบเพื่อยกเลิกการจอง";
    redirectTo('?page=login');
}

function handleCancelBooking($conn) {
    // ตรวจสอบว่ามีการส่ง booking_id มาหรือไม่
    if (isset($_GET['id'])) {
        $booking_id = (int)$_GET['id']; // แปลงเป็น int เพื่อความปลอดภัย
        $user_id = $_SESSION['user_id']; // ID ของผู้ใช้ที่ล็อกอินอยู่

        // เตรียมคำสั่ง SQL เพื่ออัปเดตสถานะการจอง
        // สำคัญ: ต้องตรวจสอบ user_id ด้วย เพื่อให้แน่ใจว่าผู้ใช้ยกเลิกการจองของตนเองเท่านั้น
        $sql = "UPDATE bookings SET status = 'cancelled' WHERE booking_id = ? AND user_id = ?";
        
        $stmt = $conn->prepare($sql);
        if ($stmt) {
            $stmt->bind_param("ii", $booking_id, $user_id);
            if ($stmt->execute()) {
                // ตรวจสอบว่ามีแถวใดถูกอัปเดตหรือไม่
                if ($stmt->affected_rows > 0) {
                    $_SESSION['message'] = "การจองหมายเลข " . htmlspecialchars($booking_id) . " ถูกยกเลิกเรียบร้อยแล้ว";
                } else {
                    $_SESSION['error'] = "ไม่พบการจองที่คุณสามารถยกเลิกได้ (อาจถูกยกเลิกไปแล้ว หรือไม่ใช่การจองของคุณ)";
                }
            } else {
                $_SESSION['error'] = "เกิดข้อผิดพลาดในการยกเลิกการจอง: " . $stmt->error;
            }
            $stmt->close();
        } else {
            $_SESSION['error'] = "เกิดข้อผิดพลาดในการเตรียมคำสั่ง SQL: " . $conn->error;
        }
    } else {
        $_SESSION['error'] = "ไม่พบรหัสการจองที่ต้องการยกเลิก";
    }

    // Redirect กลับไปยังหน้าประวัติการจองเสมอ
    redirectTo('?page=booking_history');
}
?>