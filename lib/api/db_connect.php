<?php
date_default_timezone_set('Asia/Manila');
// Database connection settings
$servername = "localhost"; // XAMPP typically uses localhost
$username = "root";        // Default username for XAMPP is root
$password = "";            // Default password for XAMPP is empty
$dbname = "attendance_test"; // Name of your database

// Create a connection to the MySQL database
$conn = new mysqli($servername, $username, $password, $dbname);

// Check if the connection is successful
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Connection successful
?>
