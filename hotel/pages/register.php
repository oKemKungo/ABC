<?php
// **สำคัญมาก: ต้องไม่มีช่องว่าง, บรรทัดว่าง, หรืออักขระใดๆ ก่อนแท็ก <?php นี้เด็ดขาด**
// ไฟล์นี้มีเพียงโค้ดสำหรับจัดการหน้า Register เท่านั้น
// ไม่ควรมี session_start(), การเชื่อมต่อ DB, หรือ require_once ของไฟล์อื่นๆ
// เพราะ index.php ได้จัดการสิ่งเหล่านี้ไว้หมดแล้ว

function handleRegister($conn) {
    $success_message = '';
    $error_message = '';

    // --- ส่วนประมวลผล POST Request (สมัครสมาชิก) ---
    // ตรวจสอบและดำเนินการ redirectTo หากสำเร็จ
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        $username = $_POST['username'] ?? '';
        $email = $_POST['email'] ?? '';
        $password = $_POST['password'] ?? '';
        $confirm_password = $_POST['confirm_password'] ?? '';

        if (empty($username) || empty($email) || empty($password) || empty($confirm_password)) {
            $error_message = "กรุณากรอกข้อมูลให้ครบถ้วน";
        } elseif ($password !== $confirm_password) {
            $error_message = "รหัสผ่านไม่ตรงกัน";
        } elseif (strlen($password) < 6) {
            $error_message = "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร";
        } else {
            $stmt = $conn->prepare("SELECT user_id FROM users WHERE username = ? OR email = ?");
            $stmt->bind_param("ss", $username, $email);
            $stmt->execute();
            $stmt->store_result();

            if ($stmt->num_rows > 0) {
                $error_message = "ชื่อผู้ใช้หรืออีเมลนี้ถูกใช้งานแล้ว";
            } else {
                $hashed_password = password_hash($password, PASSWORD_DEFAULT);
                $stmt->close(); // ปิด statement เก่าก่อนสร้างใหม่

                $stmt = $conn->prepare("INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, 'user')");
                $stmt->bind_param("sss", $username, $email, $hashed_password);

                if ($stmt->execute()) {
                    // *** ทำการ REDIRECT ทันทีที่สมัครสมาชิกสำเร็จ ***
                    redirectTo('?page=login&registration_success=true'); // ฟังก์ชัน redirectTo จะมี exit() อยู่แล้ว
                } else {
                    $error_message = "เกิดข้อผิดพลาดในการสมัครสมาชิก: " . $stmt->error;
                }
            }
            $stmt->close();
        }
    }

    // --- ส่วนแสดงผล HTML ของหน้า Register ---
    // renderHeader จะถูกเรียกเมื่อไม่มีการ redirect เกิดขึ้นจากการประมวลผล POST หรือเป็น GET request
    renderHeader("สมัครสมาชิก");
    echo "<div class='container'>"; // Start .container

    // ตรวจสอบสำหรับข้อความสำเร็จที่มาจาก URL parameter (เช่น หลังจาก redirect)
    if (isset($_GET['registration_success']) && $_GET['registration_success'] == 'true') {
        $success_message = "สมัครสมาชิกสำเร็จ! คุณสามารถ <a href='?page=login'>เข้าสู่ระบบ</a> ได้เลย";
    }

    if (!empty($success_message)) {
        echo "<p style='color: green;'>" . $success_message . "</p>";
    }
    if (!empty($error_message)) {
        echo "<p style='color: red;'>" . htmlspecialchars($error_message) . "</p>";
    }
    echo <<<HTML
        <h1>สมัครสมาชิก</h1>
        <form action="?page=register" method="POST">
            <label for="username">ชื่อผู้ใช้:</label>
            <input type="text" id="username" name="username" required>

            <label for="email">อีเมล:</label>
            <input type="email" id="email" name="email" required>

            <label for="password">รหัสผ่าน:</label>
            <input type="password" id="password" name="password" required>

            <label for="confirm_password">ยืนยันรหัสผ่าน:</label>
            <input type="password" id="confirm_password" name="confirm_password" required>

            <button type="submit">สมัครสมาชิก</button>
        </form>
HTML;
    echo "</div>"; // Close .container
    renderFooter();
}
?>