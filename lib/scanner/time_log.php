<?php
// Database connection
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "attendance_test";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}


$employeeid = $_POST['employeeid'];  
$action_type = $_POST['action_type'];  // 'time_in' or 'time_out'
$current_time = date('Y-m-d H:i:s');  
// Check if employee exists in the 'users' table
$sql = "SELECT * FROM users WHERE employeeid = '$employeeid'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // If employee exists, check attendance and log time
    if ($action_type === 'time_in') {
        // Check if already timed in today
        $attendance_sql = "SELECT * FROM attendance WHERE employeeid = '$employeeid' AND DATE(timeIn) = CURDATE()";
        $attendance_result = $conn->query($attendance_sql);

        if ($attendance_result->num_rows > 0) {
            // Already timed in today
            echo json_encode(array("status" => "error", "message" => "Already timed in today"));
        } else {
            // Insert new 'timeIn' record
            $insert_sql = "INSERT INTO attendance (employeeid, timeIn) VALUES ('$employeeid', '$current_time')";
            if ($conn->query($insert_sql) === TRUE) {
                echo json_encode(array("status" => "success", "message" => "Time In logged successfully"));
            } else {
                echo json_encode(array("status" => "error", "message" => $conn->error));
            }
        }
    } elseif ($action_type === 'time_out') {
        // Check if there's a 'timeIn' record for today
        $attendance_sql = "SELECT * FROM attendance WHERE employeeid = '$employeeid' AND DATE(timeIn) = CURDATE()";
        $attendance_result = $conn->query($attendance_sql);

        if ($attendance_result->num_rows > 0) {
            // Update 'timeOut' for today
            $update_sql = "UPDATE attendance SET timeOut = '$current_time' WHERE employeeid = '$employeeid' AND DATE(timeIn) = CURDATE()";
            if ($conn->query($update_sql) === TRUE) {
                echo json_encode(array("status" => "success", "message" => "Time Out logged successfully"));
            } else {
                echo json_encode(array("status" => "error", "message" => $conn->error));
            }
        } else {
            // No 'timeIn' record for today, can't time out
            echo json_encode(array("status" => "error", "message" => "No Time In record for today"));
        }
    }
} else {
    // Employee does not exist
    echo json_encode(array("status" => "error", "message" => "Employee not found"));
}

$conn->close();
?>
