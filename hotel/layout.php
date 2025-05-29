<?php
// layout.php
// **สำคัญมาก: ต้องไม่มีช่องว่าง, บรรทัดว่าง, หรืออักขระใดๆ ก่อนแท็ก <?php นี้เด็ดขาด**
// ไฟล์นี้มีเพียงฟังก์ชัน helper และฟังก์ชัน renderHeader/renderFooter เท่านั้น
// ไม่มี session_start() หรือ output ใดๆ ที่นี่

// --- Helper Functions ---
function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

function isAdmin() {
    return isset($_SESSION['role']) && $_SESSION['role'] === 'admin';
}

function redirectTo($path) {
    header("Location: ".$path);
    exit(); // ต้องมี exit() เพื่อหยุดการทำงานของสคริปต์ทันทีหลังจาก redirect
}

// --- HTML Head & CSS (common to all pages) ---
function renderHeader($title = "ระบบจองโรงแรม") {
    // Note: The CSS is quite long. For production, you might want to move it to a separate .css file.
    echo <<<HTML
    <!DOCTYPE html>
    <html lang="th">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
        
        body { font-family: 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; margin: 0; padding: 0; background-color: #f0f2f5; color: #333; line-height: 1.6; overflow-x: hidden; }
        header { background-color: #fff; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08); padding: 15px 0; position: sticky; top: 0; z-index: 1000; }
        nav { display: flex; justify-content: flex-end; align-items: center; max-width: 1200px; margin: 0 auto; padding: 0 20px; }
        nav a { color: #555; text-decoration: none; padding: 10px 15px; font-weight: 500; transition: color 0.3s ease, background-color 0.3s ease; border-radius: 5px; }
        nav a:hover { color: #007bff; background-color: #e9f5ff; }
        nav a:first-child { margin-right: auto; font-weight: bold; color: #007bff; }
        main { display: flex; max-width: 1200px; margin: 20px auto; gap: 20px; padding: 0 20px; }
        .container { background-color: #fff; border-radius: 12px; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1); padding: 30px; flex-grow: 1; }
        .sidebar { width: 280px; background-color: #fff; border-radius: 12px; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08); padding: 20px; flex-shrink: 0; }
        .sidebar h2 { color: #333; font-size: 1.3em; margin-top: 0; margin-bottom: 20px; }
        .sidebar ul { list-style: none; padding: 0; margin: 0; }
        .sidebar ul li { margin-bottom: 10px; }
        .sidebar ul li a { display: block; padding: 8px 12px; color: #555; text-decoration: none; border-radius: 5px; transition: background-color 0.3s ease, color 0.3s ease; }
        .sidebar ul li a:hover, .sidebar ul li a.active { background-color: #e9f5ff; color: #007bff; }
        .hero-section { position: relative; width: 100%; height: 400px; margin-bottom: 30px; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1); }
        .hero-section img { width: 100%; height: 100%; object-fit: cover; filter: brightness(0.8); }
        .hero-content { position: absolute; bottom: 30px; left: 30px; color: #fff; z-index: 1; }
        .hero-content h1 { font-size: 3em; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5); }
        .hero-content p { font-size: 1.2em; margin-bottom: 20px; text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.5); }
        /* ปุ่ม Hero */
        .hero-button {
            background-color: #007bff;
            color: white;
            padding: 12px 25px;
            border: none;
            border-radius: 8px;
            font-size: 1.1em;
            cursor: pointer;
            transition: background-color 0.3s ease, transform 0.2s ease, box-shadow 0.3s ease;
            text-decoration: none;
            display: inline-block;
            box-shadow: 0 4px 8px rgba(0, 123, 255, 0.3);
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        .hero-button:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0, 123, 255, 0.4);
        }
        .hero-button:active {
            background-color: #004085;
            transform: translateY(0);
            box-shadow: 0 2px 4px rgba(0, 123, 255, 0.2);
        }
        .hero-button:focus {
            outline: none;
            box-shadow: 0 0 0 4px rgba(0, 123, 255, 0.5);
        }

        form { display: grid; grid-template-columns: 1fr; gap: 20px; padding: 20px 0; border-top: 1px solid #eee; margin-top: 20px; }
        form label { font-weight: 600; color: #555; margin-bottom: 5px; display: block; }
        input[type="date"], input[type="number"], input[type="text"], input[type="email"], input[type="tel"], input[type="password"], textarea {
            width: calc(100% - 22px);
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 8px;
            font-size: 1em;
            transition: border-color 0.3s ease, box-shadow 0.3s ease;
            box-sizing: border-box;
        }
        input[type="date"]:focus, input[type="number"]:focus, input[type="text"]:focus, input[type="email"]:focus, input[type="tel"]:focus, input[type="password"]:focus, textarea:focus {
            border-color: #007bff;
            box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.25);
            outline: none;
        }

        /* ปุ่ม Submit */
        button[type="submit"] {
            background-color: #007bff;
            color: white;
            padding: 12px 25px;
            border: none;
            border-radius: 8px;
            font-size: 1.1em;
            cursor: pointer;
            transition: background-color 0.3s ease, transform 0.2s ease, box-shadow 0.3s ease;
            width: auto;
            margin-top: 10px;
            box-shadow: 0 4px 8px rgba(0, 123, 255, 0.3);
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        button[type="submit"]:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(0, 123, 255, 0.4);
        }
        button[type="submit"]:active {
            background-color: #004085;
            transform: translateY(0);
            box-shadow: 0 2px 4px rgba(0, 123, 255, 0.2);
        }
        button[type="submit"]:focus {
            outline: none;
            box-shadow: 0 0 0 4px rgba(0, 123, 255, 0.5);
        }

        /* ปุ่ม Cancel */
        .cancel-button {
            background-color: #dc3545; /* สีแดงสำหรับยกเลิก */
            color: white;
            padding: 8px 15px; /* ขนาดที่เหมาะกับตาราง */
            border: none;
            border-radius: 5px;
            font-size: 0.9em; /* ขนาดฟอนต์เล็กกว่าปุ่มหลัก */
            cursor: pointer;
            transition: background-color 0.3s ease, transform 0.2s ease, box-shadow 0.3s ease;
            text-decoration: none; /* เพื่อใช้กับ <a> tag */
            display: inline-block; /* เพื่อให้ <a> tag สามารถกำหนด padding/margin ได้ */
            box-shadow: 0 2px 4px rgba(220, 53, 69, 0.2);
            font-weight: 500;
            text-align: center; /* จัดให้อยู่กลาง */
        }
        .cancel-button:hover {
            background-color: #c82333; /* แดงเข้มขึ้นเมื่อ hover */
            transform: translateY(-1px);
            box-shadow: 0 4px 8px rgba(220, 53, 69, 0.3);
        }
        .cancel-button:active {
            background-color: #bd2130;
            transform: translateY(0);
            box-shadow: 0 1px 2px rgba(220, 53, 69, 0.1);
        }
        .cancel-button:focus {
            outline: none;
            box-shadow: 0 0 0 3px rgba(220, 53, 69, 0.4);
        }

        .room-sections { margin-top: 30px; }
        .room-section-heading { font-size: 1.8em; color: #333; margin-bottom: 20px; border-bottom: 2px solid #eee; padding-bottom: 10px; }
        .room-list { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 30px; margin-top: 20px; }
        .room-card { background-color: #f9f9f9; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08); transition: transform 0.3s ease, box-shadow 0.3s ease; }
        .room-card:hover { transform: translateY(-5px); box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12); }
        .room-card img { width: 100%; height: 200px; object-fit: cover; display: block; }
        .room-card-content { padding: 20px; }
        .room-card h3 { font-size: 1.4em; color: #007bff; margin-top: 0; margin-bottom: 10px; }
        .room-card p { font-size: 0.95em; color: #666; margin-bottom: 8px; }
        .room-card .price { font-size: 1.3em; font-weight: bold; color: #28a745; margin-top: 15px; margin-bottom: 15px; }
        /* ปุ่มภายใน room-card */
        .room-card form button { 
            width: 100%;
            padding: 10px;
            font-size: 1em;
            border-radius: 8px;
            margin-top: 0;
            background-color: #007bff;
            color: white;
            border: none;
            cursor: pointer;
            transition: background-color 0.3s ease, transform 0.2s ease, box-shadow 0.3s ease;
            box-shadow: 0 2px 4px rgba(0, 123, 255, 0.2);
            font-weight: 500;
        }
        .room-card form button:hover {
            background-color: #0056b3;
            transform: translateY(-1px);
            box-shadow: 0 4px 8px rgba(0, 123, 255, 0.3);
        }
        .room-card form button:active {
            background-color: #004085;
            transform: translateY(0);
            box-shadow: 0 1px 2px rgba(0, 123, 255, 0.1);
        }
        .room-card form button:focus {
            outline: none;
            box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.4);
        }

        .booking-summary { background-color: #e6f7ff; border: 1px solid #b3e0ff; padding: 25px; border-radius: 10px; margin-bottom: 30px; font-size: 1.1em; line-height: 1.8; }
        .booking-summary p strong { color: #0056b3; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; background-color: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
        table th, table td { padding: 15px; text-align: left; border-bottom: 1px solid #eee; }
        table th { background-color: #007bff; color: white; font-weight: 600; }
        table tr:nth-child(even) { background-color: #f8f8f8; }
        table tr:hover { background-color: #e9f5ff; }
        footer { text-align: center; padding: 25px; margin-top: 40px; background-color: #333; color: #f4f4f4; font-size: 0.9em; box-shadow: 0 -2px 4px rgba(0, 0, 0, 0.05); }
        @media (max-width: 992px) { main { flex-direction: column; padding: 0 15px; } .sidebar { width: 100%; margin-bottom: 20px; } .container { padding: 20px; } .hero-section { height: 300px; } .hero-content { bottom: 20px; left: 20px; } .hero-content h1 { font-size: 2.2em; } .hero-content p { font-size: 1em; } form { grid-template-columns: 1fr; } }
        @media (max-width: 768px) { nav { flex-direction: column; align-items: flex-start; padding: 10px 15px; } nav a { width: 100%; text-align: center; padding: 8px 0; } nav a:first-child { margin-right: 0; margin-bottom: 10px; } .room-list { grid-template-columns: 1fr; } .hero-section { height: 250px; } .hero-content { bottom: 20px; left: 20px; } .hero-content h1 { font-size: 1.8em; } .hero-content p { font-size: 1em; } form { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <header>
        <nav>
            <a href="?page=home">หน้าหลัก</a>
HTML;
    if (isLoggedIn()) {
        echo "<a href='#'>ยินดีต้อนรับ, " . htmlspecialchars($_SESSION['username']) . "</a>";
        echo "<a href='?page=booking_history'>ประวัติการจอง</a>"; 
        
        if (isAdmin()) {
            echo "<a href='?page=admin_dashboard'>Admin Panel</a>";
        }
        echo "<a href='?page=logout'>ออกจากระบบ</a>";
    } else {
        echo "<a href='?page=login'>เข้าสู่ระบบ</a>";
        echo "<a href='?page=register'>สมัครสมาชิก</a>";
    }
    echo <<<HTML
        </nav>
    </header>
    <main>
HTML;
}

// --- HTML Footer (common to all pages) ---
function renderFooter() {
    echo <<<HTML
    </main>
    <footer>
        <p>&copy; 2024 ระบบจองโรงแรม. สงวนลิขสิทธิ์</p>
    </footer>
</body>
</html>
HTML;
}

// --- ฟังก์ชัน logout ---
function handleLogout() {
    session_unset();
    session_destroy();
    redirectTo('?page=login');
}
?>