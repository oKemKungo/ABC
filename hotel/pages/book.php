<?php
// Function to handle the booking confirmation page
function handleBook($conn) {
    if (!isLoggedIn()) {
        $_SESSION['redirect_after_login'] = $_SERVER['REQUEST_URI'];
        redirectTo('?page=login');
    }

    renderHeader("ยืนยันการจอง");
    echo "<div class='container'>"; // Start .container
    $room_id = $_POST['room_id'] ?? '';
    $check_in_date = $_POST['check_in'] ?? '';
    $check_out_date = $_POST['check_out'] ?? '';
    $guests = $_POST['guests'] ?? '';

    $room_info = null;
    if ($room_id) {
        $stmt = $conn->prepare("SELECT * FROM rooms WHERE room_id = ?");
        $stmt->bind_param("i", $room_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $room_info = $result->fetch_assoc();
        $stmt->close();
    }

    if (!$room_info) {
        echo "<p>ไม่พบข้อมูลห้องพัก</p>";
        echo "</div>"; // Close .container
        renderFooter();
        return;
    }

    $datetime1 = new DateTime($check_in_date);
    $datetime2 = new DateTime($check_out_date);
    $interval = $datetime1->diff($datetime2);
    $number_of_nights = $interval->days;
    $total_price = $room_info['price_per_night'] * $number_of_nights;

    echo "<h1>รายละเอียดการจอง</h1>";
    echo "<div class='booking-summary'>";
    echo "<p><strong>ห้องพัก:</strong> " . htmlspecialchars($room_info['room_type']) . " (หมายเลขห้อง: " . htmlspecialchars($room_info['room_number']) . ")</p>";
    echo "<p><strong>เช็คอิน:</strong> " . htmlspecialchars($check_in_date) . "</p>";
    echo "<p><strong>เช็คเอาท์:</strong> " . htmlspecialchars($check_out_date) . "</p>";
    echo "<p><strong>จำนวนคืน:</strong> " . htmlspecialchars($number_of_nights) . " คืน</p>";
    echo "<p><strong>ราคาต่อคืน:</strong> " . number_format($room_info['price_per_night'], 2) . " บาท</p>";
    echo "<p><strong>ราคารวม:</strong> <span style='font-size: 1.2em; font-weight: bold; color: green;'>" . number_format($total_price, 2) . " บาท</span></p>";
    echo "</div>";

    echo "<h2>ข้อมูลผู้ติดต่อ (จากบัญชีของคุณ)</h2>";
    echo "<p><strong>ชื่อผู้ใช้:</strong> " . htmlspecialchars($_SESSION['username']) . "</p>";
    echo "<p><strong>อีเมล:</strong> " . htmlspecialchars($_SESSION['email'] ?? 'ไม่ได้ระบุ') . "</p>"; // Ensure email is in session on login if needed

    echo "<form action='?page=confirm' method='POST'>";
    echo "<input type='hidden' name='room_id' value='" . htmlspecialchars($room_id) . "'>";
    echo "<input type='hidden' name='check_in' value='" . htmlspecialchars($check_in_date) . "'>";
    echo "<input type='hidden' name='check_out' value='" . htmlspecialchars($check_out_date) . "'>";
    echo "<input type='hidden' name='total_price' value='" . htmlspecialchars($total_price) . "'>";
    echo "<input type='hidden' name='user_id' value='" . htmlspecialchars($_SESSION['user_id']) . "'>";
    echo "<button type='submit'>ยืนยันการจอง</button>";
    echo "</form>";

    echo "</div>"; // Close .container
    renderFooter();
}
?>