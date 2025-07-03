<?php
// Include database connection file
include 'db_connect.php';  // Make sure the path is correct

if (isset($_POST['employee_id'])) {
    $employee_id = $_POST['employee_id'];

    // Debug log
    file_put_contents('php://stderr', "Received Employee ID: $employee_id\n");

    // Use a prepared statement to prevent SQL injection
    $stmt = $conn->prepare("SELECT * FROM users WHERE employeeid = ?");
    $stmt->bind_param("s", $employee_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result) {
        if ($result->num_rows > 0) {
            echo json_encode(['isValid' => true]);
        } else {
            echo json_encode(['isValid' => false, 'message' => 'Employee ID not found']);
        }
    } else {
        echo json_encode(['isValid' => false, 'message' => 'SQL query failed']);
        file_put_contents('php://stderr', "SQL Error: " . $conn->error . "\n");
    }

    $stmt->close();
} else {
    echo json_encode(['isValid' => false, 'message' => 'No employee_id provided']);
}

// Close the database connection
$conn->close();
?>
