<?php
include 'db_connect.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['employee_id'])) { // Use `employee_id` for consistency
        $employeeId = $_POST['employee_id'];
        $timestamp = date("Y-m-d H:i:s");

        // Step 1: Verify if the employee exists in the users table
        $checkUserQuery = "SELECT fullname FROM users WHERE employeeid = ?";
        $checkUserStmt = $conn->prepare($checkUserQuery);

        if (!$checkUserStmt) {
            echo json_encode(["status" => "error", "message" => "Failed to prepare user query"]);
            exit();
        }

        $checkUserStmt->bind_param("s", $employeeId);
        $checkUserStmt->execute();
        $userResult = $checkUserStmt->get_result();

        if ($userResult->num_rows > 0) {
            $user = $userResult->fetch_assoc();
            $fullname = $user['fullname'];
            $checkUserStmt->close();

            // Step 2: Check if there's already an active time-in without a time-out
            $checkAttendanceQuery = "SELECT id FROM attendance WHERE employeeid = ? AND (timeOut IS NULL OR timeOut = '0000-00-00 00:00:00') ORDER BY timeIn DESC LIMIT 1";
            $checkAttendanceStmt = $conn->prepare($checkAttendanceQuery);

            if (!$checkAttendanceStmt) {
                echo json_encode(["status" => "error", "message" => "Failed to prepare attendance query"]);
                exit();
            }

            $checkAttendanceStmt->bind_param("s", $employeeId);
            $checkAttendanceStmt->execute();
            $attendanceResult = $checkAttendanceStmt->get_result();

            if ($attendanceResult->num_rows > 0) {
                // There's an active time-in without a time-out
                echo json_encode(["status" => "error", "message" => "You are already timed in. Please time out first."]);
                $checkAttendanceStmt->close();
                exit();
            }
            $checkAttendanceStmt->close();

            // Step 3: Insert a new time-in record
            $insertQuery = "INSERT INTO attendance (employeeid, fullname, timeIn) VALUES (?, ?, ?)";
            $insertStmt = $conn->prepare($insertQuery);

            if (!$insertStmt) {
                echo json_encode(["status" => "error", "message" => "Failed to prepare insert statement"]);
                exit();
            }

            $insertStmt->bind_param("sss", $employeeId, $fullname, $timestamp);
            $insertStmt->execute();

            if ($insertStmt->affected_rows > 0) {
                echo json_encode(["status" => "success", "message" => "Time-in recorded"]);
            } else {
                echo json_encode(["status" => "error", "message" => "Failed to record time-in"]);
            }

            $insertStmt->close();
        } else {
            // Employee ID not found
            echo json_encode(["status" => "error", "message" => "Employee ID not found"]);
            $checkUserStmt->close();
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Employee ID not provided"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method"]);
}
?>
