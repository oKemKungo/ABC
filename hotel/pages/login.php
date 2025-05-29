<?php
// **สำคัญมาก: ต้องไม่มีช่องว่าง, บรรทัดว่าง, หรืออักขระใดๆ ก่อนแท็ก <?php นี้เด็ดขาด**
// ไฟล์นี้มีเพียงโค้ดสำหรับจัดการหน้า Login เท่านั้น
// ไม่ควรมี session_start(), การเชื่อมต่อ DB, หรือ require_once ของไฟล์อื่นๆ
// เพราะ index.php ได้จัดการสิ่งเหล่านี้ไว้หมดแล้ว

function handleLogin($conn) { // รับตัวแปร $conn มาจาก index.php
    $error_message = '';

    // --- ส่วนประมวลผล POST Request (ล็อกอิน) ---
    // ตรวจสอบและดำเนินการ redirectTo หากสำเร็จ
    if ($_SERVER["REQUEST_METHOD"] == "POST") {
        $username = $_POST['username'] ?? '';
        $password = $_POST['password'] ?? '';

        if (empty($username) || empty($password)) {
            $error_message = "กรุณากรอกชื่อผู้ใช้และรหัสผ่าน";
        } else {
            $stmt = $conn->prepare("SELECT user_id, username, password, email, role FROM users WHERE username = ? OR email = ?");
            $stmt->bind_param("ss", $username, $username);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows === 1) {
                $user = $result->fetch_assoc();
                if (password_verify($password, $user['password'])) {
                    $_SESSION['user_id'] = $user['user_id'];
                    $_SESSION['username'] = $user['username'];
                    $_SESSION['email'] = $user['email'];
                    $_SESSION['role'] = $user['role'];

                    // *** ทำการ REDIRECT ทันทีที่ล็อกอินสำเร็จ ***
                    if (isset($_SESSION['redirect_after_login'])) {
                        $redirect_path = $_SESSION['redirect_after_login'];
                        unset($_SESSION['redirect_after_login']);
                        redirectTo($redirect_path); // ฟังก์ชัน redirectTo จะมี exit() อยู่แล้ว
                    } elseif ($user['role'] === 'admin') {
                        redirectTo('?page=admin_dashboard'); // ฟังก์ชัน redirectTo จะมี exit() อยู่แล้ว
                    } else {
                        redirectTo('?page=home'); // ฟังก์ชัน redirectTo จะมี exit() อยู่แล้ว
                    }
                } else {
                    $error_message = "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง";
                }
            } else {
                $error_message = "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง";
            }
            $stmt->close();
        }
    }

    // --- ส่วนแสดงผล HTML ของหน้า Login ---
    // renderHeader จะถูกเรียกเมื่อไม่มีการ redirect เกิดขึ้นจากการประมวลผล POST หรือเป็น GET request
    renderHeader("เข้าสู่ระบบ");
    echo "<div class='container'>";

    if (!empty($error_message)) {
        echo "<p style='color: red;'>" . htmlspecialchars($error_message) . "</p>";
    }
    echo <<<HTML
        <h1>เข้าสู่ระบบ</h1>
        <form action="?page=login" method="POST">
            <label for="username">ชื่อผู้ใช้หรืออีเมล:</label>
            <input type="text" id="username" name="username" required>

            <label for="password">รหัสผ่าน:</label>
            <input type="password" id="password" name="password" required>

            <button type="submit">เข้าสู่ระบบ</button>
        </form>
        <p>ยังไม่มีบัญชี? <a href="?page=register">สมัครสมาชิกที่นี่</a></p>
HTML;
    echo "</div>";
    renderFooter();
}
?>