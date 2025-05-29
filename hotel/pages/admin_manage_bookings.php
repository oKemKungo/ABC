<?php
// **สำคัญมาก: ต้องไม่มีช่องว่าง, บรรทัดว่าง, หรืออักขระใดๆ ก่อนแท็ก <?php นี้เด็ดขาด**
// ไฟล์นี้มีเพียงโค้ดสำหรับจัดการหน้า Admin Manage Bookings เท่านั้น

function handleAdminManageBookings($conn) {
    // ตรวจสอบสิทธิ์ Admin
    if (!isLoggedIn() || !isAdmin()) {
        redirectTo('?page=login');
    }

    $message = '';

    // --- ส่วนประมวลผลการอัปเดตสถานะการจอง (POST request) ---
    if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['update_booking_status'])) {
        $booking_id = (int)($_POST['booking_id'] ?? 0);
        $new_status = trim($_POST['new_status'] ?? '');

        if ($booking_id > 0 && !empty($new_status)) {
            $allowed_statuses = ['รอดำเนินการ', 'ยืนยันแล้ว', 'ยกเลิก', 'เสร็จสิ้น'];
            if (in_array($new_status, $allowed_statuses)) {
                $stmt = $conn->prepare("UPDATE bookings SET status = ? WHERE booking_id = ?");
                $stmt->bind_param("si", $new_status, $booking_id);
                if ($stmt->execute()) {
                    $message = "<p style='color: green;'>อัปเดตสถานะการจอง ID: " . htmlspecialchars($booking_id) . " เป็น '" . htmlspecialchars($new_status) . "' สำเร็จ!</p>";
                } else {
                    $message = "<p style='color: red;'>เกิดข้อผิดพลาดในการอัปเดตสถานะ: " . htmlspecialchars($stmt->error) . "</p>";
                }
                $stmt->close();
            } else {
                $message = "<p style='color: red;'>สถานะไม่ถูกต้อง</p>";
            }
        } else {
            $message = "<p style='color: red;'>ข้อมูลไม่ครบถ้วนสำหรับการอัปเดตสถานะ</p>";
        }
    }

    // --- ส่วนประมวลผลการลบการจอง (POST request) ---
    if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['delete_booking_id'])) {
        $booking_id_to_delete = (int)($_POST['delete_booking_id'] ?? 0);

        if ($booking_id_to_delete > 0) {
            $stmt = $conn->prepare("DELETE FROM bookings WHERE booking_id = ?");
            $stmt->bind_param("i", $booking_id_to_delete);
            if ($stmt->execute()) {
                $message = "<p style='color: green;'>ลบการจอง ID: " . htmlspecialchars($booking_id_to_delete) . " สำเร็จ!</p>";
            } else {
                $message = "<p style='color: red;'>เกิดข้อผิดพลาดในการลบการจอง: " . htmlspecialchars($stmt->error) . "</p>";
            }
            $stmt->close();
        } else {
            $message = "<p style='color: red;'>ไม่พบ ID การจองที่ต้องการลบ</p>";
        }
    }

    renderHeader("จัดการการจอง"); // เรียกใช้ renderHeader จาก layout.php
    echo "<div class='container'>";
    echo "<h1>จัดการการจอง</h1>";

    if (!empty($message)) {
        echo $message;
    }

    // --- ดึงข้อมูลการจองทั้งหมด ---
    $sql = "SELECT b.booking_id, u.username, r.room_type, b.check_in_date, b.check_out_date, b.total_price, b.status, b.booking_date
            FROM bookings b
            JOIN users u ON b.user_id = u.user_id
            JOIN rooms r ON b.room_id = r.room_id
            ORDER BY b.booking_date DESC";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        echo "<table class='data-table'>";
        echo "<thead>";
        echo "<tr>";
        echo "<th>ID การจอง</th>";
        echo "<th>ผู้ใช้</th>";
        echo "<th>ประเภทห้อง</th>";
        echo "<th>เช็คอิน</th>";
        echo "<th>เช็คเอาต์</th>";
        echo "<th>ราคารวม</th>";
        echo "<th>สถานะ</th>";
        echo "<th>วันที่จอง</th>";
        echo "<th>การดำเนินการ</th>";
        echo "</tr>";
        echo "</thead>";
        echo "<tbody>";
        while($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($row['booking_id']) . "</td>";
            echo "<td>" . htmlspecialchars($row['username']) . "</td>";
            echo "<td>" . htmlspecialchars($row['room_type']) . "</td>";
            echo "<td>" . htmlspecialchars($row['check_in_date']) . "</td>";
            echo "<td>" . htmlspecialchars($row['check_out_date']) . "</td>";
            echo "<td>" . number_format($row['total_price'], 2) . "</td>";
            echo "<td>" . htmlspecialchars($row['status']) . "</td>";
            echo "<td>" . htmlspecialchars($row['booking_date']) . "</td>";
            echo "<td>";
            // แบบฟอร์มอัปเดตสถานะ
            echo "<form method='POST' style='display:inline-block; margin-right: 5px;'>";
            echo "<input type='hidden' name='booking_id' value='" . htmlspecialchars($row['booking_id']) . "'>";
            echo "<select name='new_status' onchange='this.form.submit()' style='padding: 5px; border-radius: 5px; border: 1px solid #ccc;'>";
            $statuses = ['รอดำเนินการ', 'ยืนยันแล้ว', 'ยกเลิก', 'เสร็จสิ้น'];
            foreach ($statuses as $status) {
                $selected = ($row['status'] === $status) ? 'selected' : '';
                echo "<option value='" . htmlspecialchars($status) . "' " . $selected . ">" . htmlspecialchars($status) . "</option>";
            }
            echo "</select>";
            echo "<input type='hidden' name='update_booking_status' value='1'>"; // ตัวบ่งชี้ว่าเป็นการอัปเดตสถานะ
            echo "</form>";

            // ปุ่มลบ
            echo "<form method='POST' style='display:inline-block;' onsubmit='return confirm(\"คุณแน่ใจหรือไม่ที่จะลบการจองนี้?\");'>";
            echo "<input type='hidden' name='delete_booking_id' value='" . htmlspecialchars($row['booking_id']) . "'>";
            echo "<button type='submit' style='background-color: #dc3545; color: white; border: none; padding: 5px 10px; cursor: pointer; border-radius: 5px;'>ลบ</button>";
            echo "</form>";
            echo "</td>";
            echo "</tr>";
        }
        echo "</tbody>";
        echo "</table>";
    } else {
        echo "<p>ไม่พบการจอง</p>";
    }
    echo "<p><a href='?page=admin_dashboard'>กลับไปหน้า Admin Dashboard</a></p>";
    echo "</div>"; // Close .container
    renderFooter();
}