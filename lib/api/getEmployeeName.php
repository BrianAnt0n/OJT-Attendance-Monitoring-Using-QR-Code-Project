<?php
include 'db_connect.php'; 

if (isset($_GET['employeeId'])) {
    $employeeId = $_GET['employeeId'];
    
   
    $stmt = $conn->prepare("SELECT fullname FROM employees WHERE employeeId = ?");
    $stmt->bind_param("s", $employeeId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        echo json_encode(['name' => $row['fullname']]);
    } else {
        echo json_encode(['name' => 'Unknown']);
    }

    $stmt->close();
    $conn->close();
} else {
    echo json_encode(['error' => 'Employee ID not provided']);
}
?>
