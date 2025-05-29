<?php
// Function to handle user logout
function handleLogout() {
    session_unset();
    session_destroy();
    redirectTo('?page=login');
}
?>