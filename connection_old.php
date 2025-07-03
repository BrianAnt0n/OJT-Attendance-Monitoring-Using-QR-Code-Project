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
    die("Connection failed: " . $conn->connect_error);
}

// Handle the AJAX request for time-in
if (isset($_POST['employee_id'])) {
    $employee_id = $_POST['employee_id'];

    // Fetch the employee's full name from the users table
    $user_info_sql = "SELECT fullname FROM users WHERE id = $employee_id";
    $user_info_result = $conn->query($user_info_sql);

    if ($user_info_result->num_rows > 0) {
        $user_info = $user_info_result->fetch_assoc();
        $employee_name = $user_info['fullname'];

        // Check if the employee is already clocked in
        $check_sql = "SELECT * FROM attendance WHERE employeeid = $employee_id AND isTimeIn = 1 AND timeOut = '0000-00-00 00:00:00'";
        $check_result = $conn->query($check_sql);

        if ($check_result->num_rows == 0) {
            // If no active session, insert a new time-in record
            $current_time = date('Y-m-d H:i:s');
            $insert_sql = "INSERT INTO attendance (employeeid, fullname, timeIn, isTimeIn, timeOut) 
                           VALUES ($employee_id, '$employee_name', '$current_time', 1, '0000-00-00 00:00:00')";

            if ($conn->query($insert_sql) === TRUE) {
                // Respond with JSON for success
                echo json_encode([
                    'status' => 'success', 
                    'message' => "Time in recorded for: $employee_name (employee ID: $employee_id) with timeIn: $current_time"
                ]);
            } else {
                // Respond with JSON for error
                echo json_encode(['status' => 'error', 'message' => 'Error inserting record: ' . $conn->error]);
            }
        } else {
            echo json_encode(['status' => 'error', 'message' => "Employee: $employee_name (employee ID: $employee_id) is already clocked in."]);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Error: Employee not found.']);
    }
    exit;
}

// Check if "Time Out" request was submitted
if (isset($_POST['timeout_employeeid'])) {
    $employee_id = $_POST['timeout_employeeid'];
    $current_time_out = date('Y-m-d H:i:s');

    // Fetch the employee's full name from the users table
    $user_info_sql = "SELECT fullname FROM users WHERE id = $employee_id";
    $user_info_result = $conn->query($user_info_sql);
    
    if ($user_info_result->num_rows > 0) {
        $user_info = $user_info_result->fetch_assoc();
        $employee_name = $user_info['fullname'];
        
        // Update the attendance record for the specified employee ID
        $update_sql = "UPDATE attendance 
                       SET timeOut = '$current_time_out', isTimeIn = 0 
                       WHERE employeeid = $employee_id AND isTimeIn = 1 AND timeOut = '0000-00-00 00:00:00'";

        if ($conn->query($update_sql) === TRUE) {
            // Output message with employee full name
            echo json_encode([
                'status' => 'success',
                'message' => "Time out recorded for: $employee_name (employee ID: $employee_id) with timeOut: $current_time_out"
            ]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Error updating record: ' . $conn->error]);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Error: Employee not found.']);
    }
    exit;
}

// Fetch all users for the dropdown
$users_sql = "SELECT id, fullname FROM users";
$users_result = $conn->query($users_sql);

// Display the form with employee dropdown
if ($users_result->num_rows > 0) {
    echo "<h3>Select an Employee to Time In</h3>";
    echo "<select id='employeeSelect'>";
    echo "<option value=''>Select Employee</option>"; // Default option
    
    while($user_row = $users_result->fetch_assoc()) {
        echo "<option value='" . $user_row['id'] . "'>" . $user_row['fullname'] . "</option>";
    }
    
    echo "</select><br>";
}

// Display the attendance records
$display_sql = "SELECT id, employeeid, fullname, timeIn, timeOut, isTimeIn FROM attendance";
$display_result = $conn->query($display_sql);

if ($display_result->num_rows > 0) {
    echo "<h3>Attendance Records:</h3>";
    echo "<table border='1' cellpadding='5' cellspacing='0'>
            <tr>
                <th>ID</th>
                <th>Employee ID</th>
                <th>Full Name</th>
                <th>Time In</th>
                <th>Time Out</th>
                <th>Action</th>
            </tr>";
    
    // Fetch and display each row of the attendance records
    while($attendance_row = $display_result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $attendance_row['id'] . "</td>";
        echo "<td>" . $attendance_row['employeeid'] . "</td>";
        echo "<td>" . $attendance_row['fullname'] . "</td>";
        echo "<td>" . $attendance_row['timeIn'] . "</td>";
        echo "<td>" . ($attendance_row['timeOut'] === '0000-00-00 00:00:00' ? 'Pending' : $attendance_row['timeOut']) . "</td>";
  
        // Show the "Time Out" button only if isTimeIn is 1 and timeOut is still '0000-00-00 00:00:00'
        if ($attendance_row['isTimeIn'] == 1 && $attendance_row['timeOut'] === '0000-00-00 00:00:00') {
            echo "<td>
                    <form method='POST' class='timeout-form'>
                        <input type='hidden' name='timeout_employeeid' value='" . $attendance_row['employeeid'] . "' />
                        <input type='submit' name='timeout' value='Time Out' />
                    </form>
                  </td>";
        } else {
            echo "<td>No Action Available</td>";
        }

        echo "</tr>";
    }

    echo "</table>";
} else {
    echo "No attendance records found.";
}

// Close connection
$conn->close();
?>

<!-- Add the JavaScript to handle the dropdown selection -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
$(document).ready(function() {
    // Handle time-in via AJAX
    $('#employeeSelect').change(function() {
        var employeeId = $(this).val();

        if (employeeId !== '') {
            // Make an AJAX request to time in the selected employee
            $.ajax({
                type: "POST",
                url: "", // Keep the same PHP page
                data: { employee_id: employeeId },
                dataType: "json",
                success: function(response) {
                    if (response.status === 'success') {
                        alert(response.message);
                        $('#employeeSelect').val(''); // Clear the dropdown
                        location.reload(); // Reload the page to update attendance table
                    } else {
                        alert(response.message);
                    }
                },
                error: function(xhr, status, error) {
                    console.log("Error: " + error);
                    console.log("XHR Response: " + xhr.responseText);
                    alert("An error occurred while timing in.");
                }
            });
        }
    });

    // Handle time-out via AJAX
    $('.timeout-form').submit(function(e) {
        e.preventDefault(); // Prevent the form from submitting normally
        var employeeId = $(this).find('input[name="timeout_employeeid"]').val();

        $.ajax({
            type: "POST",
            url: "", // Keep the same PHP page
            data: { timeout_employeeid: employeeId },
            dataType: "json",
            success: function(response) {
                if (response.status === 'success') {
                    alert(response.message);
                    location.reload(); // Reload the page to update attendance table
                } else {
                    alert(response.message);
                }
            },
            error: function(xhr, status, error) {
                console.log("Error: " + error);
                console.log("XHR Response: " + xhr.responseText);
                alert("An error occurred while timing out.");
            }
        });
    });
});
</script>
