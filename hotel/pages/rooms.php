<?php
// Function to handle displaying available rooms
function handleRooms($conn) {
    renderHeader("ห้องว่าง");
    $check_in_date = $_GET['check_in'] ?? '';
    $check_out_date = $_GET['check_out'] ?? '';
    $guests = $_GET['guests'] ?? 1;

    $available_rooms = [];

    if ($check_in_date && $check_out_date) {
        $sql = "SELECT * FROM rooms
                WHERE capacity >= ?
                AND room_id NOT IN (
                    SELECT room_id FROM bookings
                    WHERE (
                        (check_in_date <= ? AND check_out_date >= ?) OR
                        (check_in_date >= ? AND check_in_date < ?) OR
                        (check_out_date > ? AND check_out_date <= ?)
                    ) AND status != 'cancelled'
                )";

        $stmt = $conn->prepare($sql);
        $stmt->bind_param("issssss", $guests, $check_out_date, $check_in_date, $check_in_date, $check_out_date, $check_in_date, $check_out_date);
        $stmt->execute();
        $result = $stmt->get_result();

        while ($row = $result->fetch_assoc()) {
            $available_rooms[] = $row;
        }
        $stmt->close();
    }

    // Sidebar for Filters
    echo <<<HTML
        <div class="sidebar">
            <h2>ตัวเลือกการค้นหา</h2>
            <form action="?page=rooms" method="GET">
                <input type="hidden" name="page" value="rooms">
                <label for="check_in">วันที่เช็คอิน:</label>
                <input type="date" id="check_in" name="check_in" value="{$check_in_date}" required>

                <label for="check_out">วันที่เช็คเอาท์:</label>
                <input type="date" id="check_out" name="check_out" value="{$check_out_date}" required>

                <label for="guests">จำนวนผู้เข้าพัก:</label>
                <input type="number" id="guests" name="guests" min="1" value="{$guests}" required>

                <button type="submit">แก้ไขการค้นหา</button>
            </form>
            <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
            <h2>ประเภทห้อง</h2>
            <ul>
                <li><a href="#">Standard Room</a></li>
                <li><a href="#">Deluxe Room</a></li>
                <li><a href="#">Suite</a></li>
                <li><a href="#">Family Room</a></li>
            </ul>
            </div>
    HTML;

    // Main Content Area
    echo "<div class='container'>";
    echo "<h1>ห้องว่างสำหรับวันที่ " . htmlspecialchars($check_in_date) . " ถึง " . htmlspecialchars($check_out_date) . "</h1>";
    if (!empty($available_rooms)) {
        echo "<div class='room-list'>";
        foreach ($available_rooms as $room) {
            echo "<div class='room-card'>";
            echo "<img src='" . htmlspecialchars($room['image_url'] ?? 'https://via.placeholder.com/300x200?text=Room+Image') . "' alt='" . htmlspecialchars($room['room_type']) . "'>";
            echo "<div class='room-card-content'>";
            echo "<h3>" . htmlspecialchars($room['room_type']) . " (ห้อง: " . htmlspecialchars($room['room_number']) . ")</h3>";
            echo "<p>" . htmlspecialchars(substr($room['description'], 0, 120)) . "...</p>"; // Truncate description
            echo "<p>รองรับ: " . htmlspecialchars($room['capacity']) . " ท่าน</p>";
            echo "<p class='price'>" . number_format($room['price_per_night'], 2) . " บาท/คืน</p>";
            echo "<form action='?page=book' method='POST'>";
            echo "<input type='hidden' name='room_id' value='" . htmlspecialchars($room['room_id']) . "'>";
            echo "<input type='hidden' name='check_in' value='" . htmlspecialchars($check_in_date) . "'>";
            echo "<input type='hidden' name='check_out' value='" . htmlspecialchars($check_out_date) . "'>";
            echo "<input type='hidden' name='guests' value='" . htmlspecialchars($guests) . "'>";
            echo "<button type='submit'>จองห้องนี้</button>";
            echo "</form>";
            echo "</div></div>"; // Close room-card-content and room-card
        }
        echo "</div>"; // Close room-list
    } else {
        echo "<p>ไม่พบห้องว่างสำหรับวันที่และจำนวนผู้เข้าพักที่คุณเลือก</p>";
    }
    echo "</div>"; // Close .container
    renderFooter();
}
?>