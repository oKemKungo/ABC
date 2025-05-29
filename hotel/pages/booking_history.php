<?php
// Function to handle the booking history page
function handleBookingHistory($conn) {
    // ตรวจสอบว่าผู้ใช้ล็อกอินแล้วหรือไม่
    if (!isLoggedIn()) {
        $_SESSION['redirect_after_login'] = '?page=booking_history'; // เก็บ URL ปัจจุบัน
        redirectTo('?page=login');
        exit(); // สำคัญ: ต้อง exit() หลังจาก redirect
    }

    renderHeader("ประวัติการจองของฉัน");

    $user_id = $_SESSION['user_id'];

    echo <<<HTML
    <div class="container">
        <h1>ประวัติการจองของคุณ</h1>
HTML;

    // SQL query to fetch booking history for the logged-in user
    // Join with rooms table to get room type and price
    // ตรวจสอบให้แน่ใจว่าคอลัมน์ num_guests มีอยู่ในตาราง bookings แล้ว
    $sql = "SELECT
                b.booking_id,
                r.room_type,
                b.check_in_date,
                b.check_out_date,
                b.total_price,
                b.num_guests,
                b.status,
                b.booking_date
            FROM
                bookings b
            JOIN
                rooms r ON b.room_id = r.room_id
            WHERE
                b.user_id = ?
            ORDER BY
                b.booking_date DESC";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        echo <<<HTML
        <table>
            <thead>
                <tr>
                    <th>รหัสการจอง</th>
                    <th>ประเภทห้องพัก</th>
                    <th>วันที่เช็คอิน</th>
                    <th>วันที่เช็คเอาท์</th>
                    <th>จำนวนผู้เข้าพัก</th>
                    <th>ราคารวม</th>
                    <th>สถานะ</th>
                    <th>วันที่จอง</th>
                    <th>การดำเนินการ</th> </tr>
            </thead>
            <tbody>
HTML;
        while($booking = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($booking['booking_id']) . "</td>";
            echo "<td>" . htmlspecialchars($booking['room_type']) . "</td>";
            echo "<td>" . htmlspecialchars($booking['check_in_date']) . "</td>";
            echo "<td>" . htmlspecialchars($booking['check_out_date']) . "</td>";
            echo "<td>" . htmlspecialchars($booking['num_guests']) . "</td>";
            echo "<td>" . number_format($booking['total_price'], 2) . " บาท</td>";
            echo "<td>" . htmlspecialchars($booking['status']) . "</td>";
            echo "<td>" . htmlspecialchars(date('d/m/Y', strtotime($booking['booking_date']))) . "</td>";
            echo "<td>";
            // เพิ่มปุ่มยกเลิก ถ้าสถานะยังไม่ใช่ 'cancelled'
            if ($booking['status'] !== 'cancelled') { // ตัวอย่างการตรวจสอบสถานะ
                echo "<a href='?page=cancel_booking&id=" . htmlspecialchars($booking['booking_id']) . "' class='cancel-button'>ยกเลิก</a>";
            } else {
                echo "ยกเลิกแล้ว";
            }
            echo "</td>";
            echo "</tr>";
        }
        echo <<<HTML
            </tbody>
        </table>
HTML;
    } else {
        echo "<p>คุณยังไม่มีประวัติการจอง</p>";
    }

    echo <<<HTML
    </div>
HTML;

    renderFooter();
}
?>