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

            // Step 2: Ensure there is an active time-in record without time-out
            $checkAttendanceQuery = "SELECT id FROM attendance WHERE employeeid = ? AND (timeOut IS NULL OR timeOut = '0000-00-00 00:00:00') ORDER BY timeIn DESC LIMIT 1";
            $checkAttendanceStmt = $conn->prepare($checkAttendanceQuery);

            if (!$checkAttendanceStmt) {
                echo json_encode(["status" => "error", "message" => "Failed to prepare attendance query"]);
                exit();
            }

            $checkAttendanceStmt->bind_param("s", $employeeId);
            $checkAttendanceStmt->execute();
            $attendanceResult = $checkAttendanceStmt->get_result();

            if ($attendanceResult->num_rows === 0) {
                // No active time-in record found for this employee
                echo json_encode(["status" => "error", "message" => "No active time-in found. You cannot time out without timing in."]);
                $checkAttendanceStmt->close();
                exit();
            }

            $attendance = $attendanceResult->fetch_assoc();
            $attendanceId = $attendance['id'];
            $checkAttendanceStmt->close();

            // Step 3: Update the timeOut for the active time-in record
            $updateQuery = "UPDATE attendance SET timeOut = ? WHERE id = ?";
            $updateStmt = $conn->prepare($updateQuery);

            if (!$updateStmt) {
                echo json_encode(["status" => "error", "message" => "Failed to prepare update statement"]);
                exit();
            }

            $updateStmt->bind_param("si", $timestamp, $attendanceId);
            $updateStmt->execute();

            if ($updateStmt->affected_rows > 0) {
                echo json_encode(["status" => "success", "message" => "Time-out recorded"]);
            } else {
                echo json_encode(["status" => "error", "message" => "Failed to record time-out"]);
            }

            $updateStmt->close();
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
