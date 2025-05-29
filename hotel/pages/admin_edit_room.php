<?php
// **สำคัญมาก: ต้องไม่มีช่องว่าง, บรรทัดว่าง, หรืออักขระใดๆ ก่อนแท็ก <?php นี้เด็ดขาด**
// ไฟล์นี้มีเพียงโค้ดสำหรับจัดการหน้า Admin Edit Room เท่านั้น

function handleAdminEditRoom($conn) {
    // ตรวจสอบสิทธิ์ Admin
    if (!isLoggedIn() || !isAdmin()) {
        redirectTo('?page=login');
    }

    $room_id = $_GET['room_id'] ?? 0;
    $message = '';
    $room_data = null;

    // --- ส่วนประมวลผลการส่งฟอร์มแก้ไขห้องพัก (POST Request) ---
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        $room_id_post = $_POST['room_id'] ?? 0;
        $room_type = trim($_POST['room_type'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $price_per_night = (float)($_POST['price_per_night'] ?? 0);
        $capacity = (int)($_POST['capacity'] ?? 1);
        $image_url = trim($_POST['image_url'] ?? ''); // URL รูปภาพ
        $is_available = isset($_POST['is_available']) ? 1 : 0; // checkbox

        // ตรวจสอบข้อมูลที่รับมา
        if ($room_id_post <= 0 || empty($room_type) || empty($description) || $price_per_night <= 0 || $capacity <= 0) {
            $message = "<p style='color: red;'>กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้องสำหรับการแก้ไขห้องพัก</p>";
        } else {
            // เตรียมคำสั่ง SQL สำหรับการอัปเดต
            $stmt = $conn->prepare("UPDATE rooms SET room_type = ?, description = ?, price_per_night = ?, capacity = ?, image_url = ?, is_available = ? WHERE room_id = ?");
            $stmt->bind_param("ssdissi", $room_type, $description, $price_per_night, $capacity, $image_url, $is_available, $room_id_post);

            if ($stmt->execute()) {
                $message = "<p style='color: green;'>แก้ไขข้อมูลห้องพักสำเร็จ!</p>";
                // โหลดข้อมูลห้องพักใหม่หลังจากบันทึก (เพื่อให้ฟอร์มแสดงข้อมูลที่อัปเดต)
                $room_id = $room_id_post; // ตรวจสอบให้แน่ใจว่า room_id ที่ใช้ query คือตัวที่เพิ่งแก้ไข
                $stmt_fetch = $conn->prepare("SELECT * FROM rooms WHERE room_id = ?");
                $stmt_fetch->bind_param("i", $room_id);
                $stmt_fetch->execute();
                $result_fetch = $stmt_fetch->get_result();
                if ($result_fetch->num_rows === 1) {
                    $room_data = $result_fetch->fetch_assoc();
                }
                $stmt_fetch->close();

            } else {
                $message = "<p style='color: red;'>เกิดข้อผิดพลาดในการแก้ไขห้องพัก: " . $stmt->error . "</p>";
            }
            $stmt->close();
        }
    }

    // --- ส่วนดึงข้อมูลห้องพักสำหรับแสดงในฟอร์ม (GET Request หรือหลังจากการแก้ไข) ---
    // ตรวจสอบว่า $room_data ยังเป็น null หรือไม่ (กรณีเป็น GET request ครั้งแรก หรือแก้ไขแล้ว)
    if ($room_data === null && $room_id > 0) {
        $stmt = $conn->prepare("SELECT * FROM rooms WHERE room_id = ?");
        $stmt->bind_param("i", $room_id);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 1) {
            $room_data = $result->fetch_assoc();
        } else {
            $message = "<p style='color: red;'>ไม่พบข้อมูลห้องพักที่ต้องการแก้ไข</p>";
        }
        $stmt->close();
    }


    renderHeader("แก้ไขห้องพัก");
    echo "<div class='container'>";
    echo "<h1>แก้ไขห้องพัก</h1>";
    echo $message; // แสดงข้อความสถานะ (สำเร็จ/ผิดพลาด)

    if ($room_data) {
        // ใช้ htmlspecialchars กับทุกตัวแปรที่แสดงผลใน attribute value
        // และใช้ <?php echo แทน <?= เพื่อความเข้ากันได้สูงสุด
        $room_id_html = htmlspecialchars($room_data['room_id'] ?? '');
        $room_type_html = htmlspecialchars($room_data['room_type'] ?? '');
        $description_html = htmlspecialchars($room_data['description'] ?? '');
        $price_per_night_html = htmlspecialchars($room_data['price_per_night'] ?? '');
        $capacity_html = htmlspecialchars($room_data['capacity'] ?? '');
        $image_url_html = htmlspecialchars($room_data['image_url'] ?? '');
        $is_available_checked = ($room_data['is_available'] == 1 ? 'checked' : '');

        echo <<<HTML
        <form action="?page=admin_edit_room" method="POST">
            <input type="hidden" name="room_id" value="{$room_id_html}">

            <label for="room_type">ประเภทห้อง:</label>
            <input type="text" id="room_type" name="room_type" value="{$room_type_html}" required>

            <label for="description">รายละเอียด:</label>
            <textarea id="description" name="description" rows="5" required>{$description_html}</textarea>

            <label for="price_per_night">ราคาต่อคืน (บาท):</label>
            <input type="number" id="price_per_night" name="price_per_night" step="0.01" min="0" value="{$price_per_night_html}" required>

            <label for="capacity">จำนวนผู้เข้าพักสูงสุด:</label>
            <input type="number" id="capacity" name="capacity" min="1" value="{$capacity_html}" required>

            <label for="image_url">URL รูปภาพ:</label>
            <input type="text" id="image_url" name="image_url" value="{$image_url_html}">

            <label for="is_available">
                <input type="checkbox" id="is_available" name="is_available" value="1" {$is_available_checked}>
                เปิดให้จอง
            </label>
            <br>

            <button type="submit">บันทึกการแก้ไข</button>
        </form>
HTML;
    } else {
        // หากไม่มีข้อมูลห้องพักที่ถูกต้องให้แก้ไข จะแสดงข้อความ "ไม่พบข้อมูลห้องพัก"
        // และอาจจะให้ลิงก์กลับไปหน้าจัดการห้องพัก
        if (empty($message)) { // ถ้ายังไม่มี message แสดงว่า room_id ไม่ถูกต้องตั้งแต่แรก
             echo "<p style='color: red;'>ไม่พบข้อมูลห้องพักที่ต้องการแก้ไข</p>";
        }
    }
    echo "<p><a href='?page=admin_manage_rooms'>กลับไปหน้าจัดการห้องพัก</a></p>";
    echo "</div>"; // Close .container
    renderFooter();
}
?>