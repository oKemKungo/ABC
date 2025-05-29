<?php
// Function to handle the home page
function handleHome($conn) {
    renderHeader("ค้นหาห้องพัก");
    // Hero Section
    echo <<<HTML
        <div class="hero-section">
            <img src="images/hotel1.jpg" alt="Luxury Hotel">
            <div class="hero-content">
                <h1>สัมผัสประสบการณ์การพักผ่อนระดับโลก</h1>
                <p>ค้นหาห้องพักที่สมบูรณ์แบบสำหรับทริปถัดไปของคุณ</p>
                <a href="#search-form-container" class="hero-button">เริ่มค้นหา</a>
            </div>
        </div>
    HTML;

    // Sidebar for Filters (Example - you can expand this)
    echo <<<HTML
        <div class="sidebar">
            <h2 id="search-form-container">ตัวเลือกการค้นหา</h2>
            <form action="?page=rooms" method="GET">
                <input type="hidden" name="page" value="rooms">
                <label for="check_in">วันที่เช็คอิน:</label>
                <input type="date" id="check_in" name="check_in" required>

                <label for="check_out">วันที่เช็คเอาท์:</label>
                <input type="date" id="check_out" name="check_out" required>

                <label for="guests">จำนวนผู้เข้าพัก:</label>
                <input type="number" id="guests" name="guests" min="1" value="1" required>

                <button type="submit">ค้นหาห้องว่าง</button>
            </form>
            <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
            <h2>ประเภทห้อง</h2>
            <ul>
                <li><a href="">Standard Room</a></li>
                <li><a href="">Deluxe Room</a></li>
                <li><a href="">Suite</a></li>
                <li><a href="">Family Room</a></li>
            </ul>
            </div>
    HTML;

    // Main Content Area
    echo "<div class='container'>";
    echo "<h1>โรงแรมยอดนิยม</h1>";

    // You can add a section to display featured rooms here, similar to handleRooms
    $featured_rooms_sql = "SELECT * FROM rooms ORDER BY price_per_night DESC LIMIT 6"; // Example query
    $featured_result = $conn->query($featured_rooms_sql);

    if ($featured_result->num_rows > 0) {
        echo "<h2 class='room-section-heading'>ห้องพักแนะนำ</h2>";
        echo "<div class='room-list'>";
        while($room = $featured_result->fetch_assoc()) {
             echo "<div class='room-card'>";
             echo "<img src='" . htmlspecialchars($room['image_url'] ?? '00000') . "' alt='" . htmlspecialchars($room['room_type']) . "'>";
             echo "<div class='room-card-content'>";
             echo "<h3>" . htmlspecialchars($room['room_type']) . "</h3>";
             echo "<p>" . htmlspecialchars(substr($room['description'], 0, 100)) . "...</p>"; // Truncate description
             echo "<p>รองรับ: " . htmlspecialchars($room['capacity']) . " ท่าน</p>";
             echo "<p class='price'>" . number_format($room['price_per_night'], 2) . " บาท/คืน</p>";
             echo "<form action='?page=book' method='POST'>";
             echo "<input type='hidden' name='room_id' value='" . htmlspecialchars($room['room_id']) . "'>";
             // You'd also need check_in/out dates for booking, maybe pre-fill with next available dates or ask user
             echo "<button type='submit'>ดูรายละเอียดและจอง</button>";
             echo "</form>";
             echo "</div></div>";
        }
        echo "</div>";
    }
    echo "</div>"; // Close .container
    renderFooter();
}
?>