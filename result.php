<?php
// Set timezone to Philippine time (Asia/Manila)
date_default_timezone_set('Asia/Manila');

// Database connection settings
$servername = "localhost";
$username = "root"; // Change if necessary
$password = ""; // Change if necessary
$dbname = "testqr"; // Replace with your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode([
        "success" => 0,
        "message" => "Connection failed: " . $conn->connect_error
    ]));
}

// Get employee ID from the POST request
$employee_id = isset($_POST['employeeid']) ? intval($_POST['employeeid']) : 0;

// Validate employee ID
if ($employee_id <= 0) {
    echo json_encode([
        "success" => 0,
        "message" => "Invalid employee ID"
    ]);
    exit;
}

// Get the current timestamp
$current_time = date('Y-m-d H:i:s');

// Check if the employee is already timed in but has no timeOut yet
$sql = "SELECT * FROM attendance WHERE employeeid = $employee_id AND timeOut = ''";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // The employee is already timed in, so we only update the timeOut
    $row = $result->fetch_assoc();
    $attendance_id = $row['id'];
    
    // Update ONLY the timeOut with the current time, leave timeIn unchanged
    $update_sql = "UPDATE attendance SET timeOut = '$current_time' WHERE id = $attendance_id";
    
    if ($conn->query($update_sql) === TRUE) {
        echo json_encode([
            "success" => 1,
            "message" => "timeOut: " . $current_time,
            "employeeID" => $employee_id,
            "fullname" => $row['fullname']
        ]);
    } else {
        echo json_encode([
            "success" => 0,
            "message" => "Error updating time out: " . $conn->error
        ]);
    }
} else {
    // The employee has not timed in yet, insert a new timeIn record
    $sql_insert = "INSERT INTO attendance (employeeid, fullname, timeIn, timeOut)
                   SELECT id, fullname, '$current_time', '' FROM users WHERE id = $employee_id";
    
    if ($conn->query($sql_insert) === TRUE) {
        // Get the fullname from the users table for response
        $row = $conn->query("SELECT fullname FROM users WHERE id = $employee_id")->fetch_assoc();
        
        echo json_encode([
            "success" => 1,
            "message" => "timeIn: " . $current_time,
            "employeeID" => $employee_id,
            "fullname" => $row['fullname']
        ]);
    } else {
        echo json_encode([
            "success" => 0,
            "message" => "Error inserting time in record: " . $conn->error
        ]);
    }
}

// Close the connection
$conn->close();
?>
