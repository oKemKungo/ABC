<?php
// **สำคัญมาก: ต้องไม่มีช่องว่าง, บรรทัดว่าง, หรืออักขระใดๆ ก่อนแท็ก <?php นี้เด็ดขาด**
// ไฟล์นี้มีเพียงโค้ดสำหรับจัดการหน้า Admin Manage Rooms เท่านั้น

function handleAdminManageRooms($conn) {
    // ตรวจสอบสิทธิ์ Admin
    if (!isLoggedIn() || !isAdmin()) {
        redirectTo('?page=login');
    }

    $message = '';

    // --- ส่วนประมวลผลการเพิ่มห้องพักใหม่ (POST request) ---
    if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['add_room'])) {
        $room_type = trim($_POST['room_type'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $price_per_night = (float)($_POST['price_per_night'] ?? 0);
        $capacity = (int)($_POST['capacity'] ?? 1);
        $image_url = trim($_POST['image_url'] ?? '');
        $is_available = isset($_POST['is_available']) ? 1 : 0; // checkbox

        if (empty($room_type) || empty($description) || $price_per_night <= 0 || $capacity <= 0) {
            $message = "<p style='color: red;'>กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้องสำหรับการเพิ่มห้องพัก</p>";
        } else {
            // ตรวจสอบว่ามี room_type ซ้ำหรือไม่ (อาจจะไม่จำเป็น 100% แต่ช่วยป้องกันความซ้ำซ้อน)
            $stmt = $conn->prepare("SELECT room_id FROM rooms WHERE room_type = ?");
            $stmt->bind_param("s", $room_type);
            $stmt->execute();
            $stmt->store_result();

            if ($stmt->num_rows > 0) {
                $message = "<p style='color: red;'>ไม่สามารถเพิ่มห้องพักได้: ประเภทห้องนี้มีอยู่แล้ว</p>";
            } else {
                $stmt = $conn->prepare("INSERT INTO rooms (room_type, description, price_per_night, capacity, image_url, is_available) VALUES (?, ?, ?, ?, ?, ?)");
                $stmt->bind_param("ssdiss", $room_type, $description, $price_per_night, $capacity, $image_url, $is_available);

                if ($stmt->execute()) {
                    $message = "<p style='color: green;'>เพิ่มห้องพักใหม่สำเร็จ!</p>";
                } else {
                    $message = "<p style='color: red;'>เกิดข้อผิดพลาดในการเพิ่มห้องพัก: " . $stmt->error . "</p>";
                }
            }
            $stmt->close();
        }
    }

    // --- ส่วนประมวลผลการลบห้องพัก (POST request) ---
    if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['delete_room_id'])) {
        $room_id_to_delete = (int)$_POST['delete_room_id'];

        if ($room_id_to_delete > 0) {
            $stmt = $conn->prepare("DELETE FROM rooms WHERE room_id = ?");
            $stmt->bind_param("i", $room_id_to_delete);
            if ($stmt->execute()) {
                $message = "<p style='color: green;'>ลบห้องพักสำเร็จ!</p>";
            } else {
                $message = "<p style='color: red;'>เกิดข้อผิดพลาดในการลบห้องพัก: " . $stmt->error . "</p>";
            }
            $stmt->close();
        } else {
            $message = "<p style='color: red;'>ไม่พบ ID ห้องพักที่ต้องการลบ</p>";
        }
    }

    renderHeader("จัดการห้องพัก");
    echo "<div class='container'>";
    echo "<h1>จัดการห้องพัก</h1>";

    echo $message; // แสดงข้อความสถานะ (สำเร็จ/ผิดพลาด)

    // Form for adding new room
    echo "<h2>เพิ่มห้องพักใหม่</h2>";
    echo <<<HTML
        <form action="?page=admin_manage_rooms" method="POST">
            <input type="hidden" name="add_room" value="1">
            <label for="room_type">ประเภทห้อง:</label>
            <input type="text" id="room_type" name="room_type" required>

            <label for="description">รายละเอียด:</label>
            <textarea id="description" name="description" rows="5" required></textarea>

            <label for="price_per_night">ราคาต่อคืน (บาท):</label>
            <input type="number" id="price_per_night" name="price_per_night" step="0.01" min="0" required>

            <label for="capacity">จำนวนผู้เข้าพักสูงสุด:</label>
            <input type="number" id="capacity" name="capacity" min="1" required>

            <label for="image_url">URL รูปภาพ:</label>
            <input type="text" id="image_url" name="image_url">

            <label for="is_available">
                <input type="checkbox" id="is_available" name="is_available" value="1" checked>
                เปิดให้จอง
            </label>
            <br>

            <button type="submit">เพิ่มห้องพัก</button>
        </form>
    HTML;

    echo "<h2>รายการห้องพักทั้งหมด</h2>";

    $sql = "SELECT room_id, room_type, description, price_per_night, capacity, is_available, image_url FROM rooms";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        echo "<table class='data-table'>";
        echo "<thead>";
        echo "<tr>";
        echo "<th>ID</th>";
        echo "<th>ประเภทห้อง</th>";
        echo "<th>ราคา/คืน</th>";
        echo "<th>รองรับ (ท่าน)</th>";
        echo "<th>สถานะ</th>";
        echo "<th>รูปภาพ URL</th>";
        echo "<th>การจัดการ</th>"; // เพิ่มคอลัมน์นี้
        echo "</tr>";
        echo "</thead>";
        echo "<tbody>";
        while($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($row['room_id']) . "</td>";
            echo "<td>" . htmlspecialchars($row['room_type']) . "</td>";
            echo "<td>" . number_format($row['price_per_night'], 2) . "</td>";
            echo "<td>" . htmlspecialchars($row['capacity']) . "</td>";
            echo "<td>" . ($row['is_available'] ? 'พร้อมใช้งาน' : 'ไม่พร้อมใช้งาน') . "</td>";
            echo "<td>" . htmlspecialchars($row['image_url']) . "</td>";
            echo "<td>";
            // ปุ่มแก้ไข
            echo "<a href='?page=admin_edit_room&room_id=" . htmlspecialchars($row['room_id']) . "' style='background-color: #007bff; color: white; padding: 5px 10px; text-decoration: none; border-radius: 5px; margin-right: 5px;'>แก้ไข</a>";
            // ปุ่มลบ
            echo "<form method='POST' style='display:inline-block;' onsubmit='return confirm(\"คุณแน่ใจหรือไม่ที่จะลบห้องพักนี้?\");'>";
            echo "<input type='hidden' name='delete_room_id' value='" . htmlspecialchars($row['room_id']) . "'>";
            echo "<button type='submit' style='background-color: #dc3545; color: white; border: none; padding: 5px 10px; cursor: pointer; border-radius: 5px;'>ลบ</button>";
            echo "</form>";
            echo "</td>";
            echo "</tr>";
        }
        echo "</tbody>";
        echo "</table>";
    } else {
        echo "<p>ไม่พบห้องพักในระบบ</p>";
    }
    echo "</div>"; // Close .container
    renderFooter();
}
?>