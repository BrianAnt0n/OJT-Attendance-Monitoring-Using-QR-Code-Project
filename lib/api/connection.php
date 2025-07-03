<?php
// Set timezone to Philippine time (Asia/Manila)
date_default_timezone_set('Asia/Manila');

// Database connection settings
$servername = "localhost";
$username = "root"; // Change if necessary
$password = ""; // Change if necessary
$dbname = "attendance_test"; // Replace with your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);


?>
