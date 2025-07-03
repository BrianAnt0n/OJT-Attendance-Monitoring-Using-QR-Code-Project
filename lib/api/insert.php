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

// Check connection
if ($conn->connect_error) {
    die(json_encode([
        "success" => 0,
        "message" => "Connection failed: " . $conn->connect_error
    ]));
}

// Get employee ID from the POST request
$employee_id = isset($_POST['employeeid']) ? intval($_POST['employeeid']) : 1;

// Debugging: Log the incoming employee ID
error_log("Employee ID received: " . $employee_id); // Log received ID for debugging

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

// Prepare SQL to check if the employee is already timed in but has no timeOut yet
$sql = $conn->prepare("SELECT * FROM attendance WHERE employeeid = ? AND timeOut IS NULL");
$sql->bind_param("i", $employee_id);
$sql->execute();
$result = $sql->get_result();

// Log SQL Query for debugging
error_log("SQL Query for attendance: SELECT * FROM attendance WHERE employeeid = $employee_id AND timeOut IS NULL");

if ($result->num_rows > 0) {
    // The employee is already timed in, so we only update the timeOut
    $row = $result->fetch_assoc();
    $attendance_id = $row['id'];
    
    // Prepare SQL to update ONLY the timeOut with the current time
    $update_sql = $conn->prepare("UPDATE attendance SET timeOut = ? WHERE id = ?");
    $update_sql->bind_param("si", $current_time, $attendance_id);
    
    if ($update_sql->execute()) {
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
    $sql_insert = $conn->prepare("INSERT INTO attendance (employeeid, fullname, timeIn, timeOut)
                                  SELECT id, fullname, ?, NULL FROM users WHERE id = ?");
    $sql_insert->bind_param("si", $current_time, $employee_id);
    
    // Log SQL Insert for debugging
    error_log("SQL Insert Query: INSERT INTO attendance (employeeid, fullname, timeIn, timeOut) SELECT id, fullname, '$current_time', NULL FROM users WHERE id = $employee_id");
    
    if ($sql_insert->execute()) {
        // Get the fullname from the users table for response
        $fullname_sql = $conn->prepare("SELECT fullname FROM users WHERE id = ?");
        $fullname_sql->bind_param("i", $employee_id);
        $fullname_sql->execute();
        $row = $fullname_sql->get_result()->fetch_assoc();
        
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
