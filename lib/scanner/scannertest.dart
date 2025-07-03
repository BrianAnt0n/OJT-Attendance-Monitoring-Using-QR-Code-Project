// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert'; // Required for JSON encoding
import 'package:http/http.dart' as http; // For making HTTP requests

void main() => runApp(const MaterialApp(home: ScannerDevTest()));

class ScannerDevTest extends StatefulWidget {
  const ScannerDevTest({super.key});

  @override
  State<ScannerDevTest> createState() => _ScannerTestState();
}

class _ScannerTestState extends State<ScannerDevTest> {
  bool isDisplayed = false;

  String imageName = '';
  String imageFilePath = '';

  bool isButton1Active = true;
  bool isButton2Active = false;
  String? employeeId; // State variable to hold the employee ID

  Future<Uint8List> compressImage(Uint8List img) async {
    var result = await FlutterImageCompress.compressWithList(
      img,
      minHeight: 640,
      minWidth: 480,
      quality: 30,
      rotate: 0,
    );
    return result;
  }

  MobileScannerController scannerController = MobileScannerController(
    facing: CameraFacing.front,
    torchEnabled: false,
    returnImage: true,
    detectionTimeoutMs: 1000, // 1 second
    formats: [BarcodeFormat.qrCode],
  );

  void onQRDetect(BarcodeCapture capture) async {
    if (!isDisplayed) {
      setState(() {
        isDisplayed = true;
      });

      bool result = kIsWeb || await InternetConnectionChecker().hasConnection;

      if (result) {
        final List<Barcode> barcodes = capture.barcodes;
        final barcodeCount = barcodes.length;

        // Save Image (Optional)
        final webImage = await cameraController.takePicture();
        Uint8List image = await webImage.readAsBytes();
        Uint8List compressedImage = await compressImage(image);

        if (barcodeCount > 0) {
          // Extract employee ID from the QR code
          setState(() {
            employeeId = barcodes[0].rawValue ??
                ''; // Store employeeId in the state variable
          });
          print('Scanned Employee ID: $employeeId'); // Debug log

          // Step 1: Validate the employee ID by checking the database
          bool isValidEmployee = await validateEmployeeId(
              employeeId!); // Use state variable employeeId

          if (isValidEmployee) {
            // Employee ID found, proceed with time in/out
            // Call the appropriate endpoint based on the active button
            if (isButton1Active) {
              await executeTimeInOut(employeeId!, 'timein.php');
            } else if (isButton2Active) {
              await executeTimeInOut(employeeId!, 'timeout.php');
            }

            // Show success dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Employee Verified'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.memory(
                      compressedImage,
                      width: 100,
                      height: 100,
                    ),
                    SizedBox(height: 10),
                    Text('Employee ID: $employeeId'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isDisplayed = false;
                      });
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );

// Automatically close the dialog after 3 seconds
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context, rootNavigator: true)
                    .pop(); // Close the dialog
                setState(() {
                  isDisplayed = false;
                });
              }
            });
          } else {
            // Employee ID not found, show error dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Error'),
                content: Text('Employee ID not found in the database.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isDisplayed = false;
                      });
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          // No QR code detected, show error dialog
          setState(() {
            isDisplayed = false;
          });
        }
      }
    }
  }

// Step 1: Validate employee ID by sending a request to the backend
  Future<bool> validateEmployeeId(String employeeId) async {
    final url = Uri.parse(
        'http://localhost/web/qrweb-main/lib/api/validate_employee.php');
    print('Validating Employee ID: $employeeId');

    final response = await http.post(
      url,
      body: {'employee_id': employeeId}, // Use the correct key
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isValid']; // true if the employee ID exists
    } else {
      print('Failed to validate Employee ID: ${response.statusCode}');
      return false;
    }
  }

// Step 2: Execute time in/out by sending a POST request to the appropriate PHP script
  Future<void> executeTimeInOut(String? employeeId, String endpoint) async {
    if (employeeId == null) {
      print('Employee ID is null. Cannot proceed.');
      return; // Prevent execution if employeeId is null
    }

    final url = Uri.parse('http://localhost/web/qrweb-main/lib/api/$endpoint');
    print('Sending request to $url with employee_id: $employeeId');

    try {
      final response = await http.post(
        url,
        body: {'employee_id': employeeId}, // Use the correct key
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check the "status" field in the response
        if (data['status'] == 'error') {
          // Show error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text(data['message']), // Display the error message
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      employeeId = null; // Reset employeeId
                      isDisplayed = false; // Allow scanning again
                    });
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else if (data['status'] == 'success') {
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Success'),
              content: Text('Employee ${data['message']}'), // Success message
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      employeeId = null; // Reset employeeId
                      isDisplayed = false; // Allow scanning again
                    });
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        print(
            'Failed to record time in/out: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  late List<CameraDescription> cameras;
  late CameraController cameraController;

  @override
  void initState() {
    startCamera();
    super.initState();

    // Ensure dialog is shown after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isDisplayed = false;
        });
      }
    });
  }

  void startCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await cameraController.initialize().then((value) {
      if (!mounted) return;
      setState(() {}); // Refresh widget
    }).catchError((e) {
      // Handle error
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  //bool isButton1Active = true; // time in is initially active
  //bool isButton2Active = false; // time out is inactive
  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: Stack(
          children: [
            Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/header.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 30),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              child: Image(
                                image: AssetImage('assets/rgslogo1024.png'),
                                height: 140,
                                width: 140,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _clockWidget(context)),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 0,
                        height: 0,
                        child: MobileScanner(
                          fit: BoxFit.contain,
                          controller: scannerController,
                          onDetect: (capture) async {
                            onQRDetect(capture);
                          },
                        ),
                      ),
                      Center(child: CameraPreview(cameraController)),
                      const QRScannerOverlay(overlayColour: Colors.black12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              SizedBox(height: 30),
                              Text(
                                'Please make sure your face is\nvisible on the camera.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              //for buttons

              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(150, 50), //button size (width,height)
                      backgroundColor: isButton1Active
                          ? Colors.green
                          : Color(0xFF4A5759), // Button 1 color
                      foregroundColor: Color(0xFFEDF6F9),
                      textStyle: TextStyle(
                        color: Color(0xFFEDF6F9),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isButton1Active = true; // Activate Button 1
                        isButton2Active = false; // Deactivate Button 2
                        employeeId = null; // Reset employeeId
                        isDisplayed = false; // Allow scanning again
                      });
                    },
                    child: const Text('TIME IN'),
                  ),
                  const SizedBox(width: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(150, 50),
                      backgroundColor: isButton2Active
                          ? Colors.green
                          : Color(0xFF4A5759), // Button 2 color
                      foregroundColor: Color(0xFFEDF6F9),
                      textStyle: TextStyle(
                        color: Color(0xFFEDF6F9),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isButton2Active = true; // Activate Button 2
                        isButton1Active = false; // Deactivate Button 1
                        employeeId = null; // Reset employeeId
                        isDisplayed = false; // Allow scanning again
                      });
                    },
                    child: const Text('TIME OUT'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox();
    }
  }
}

Widget _clockWidget(BuildContext context) {
  return StreamBuilder(
    stream: Stream.periodic(const Duration(seconds: 1)),
    builder: (context, snapshot) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 35),
          Text(
            DateFormat.MMMMEEEEd().format(DateTime.now()),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat('hh:mm:ss').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    },
  );
}

var alertStyle = AlertStyle(
  animationType: AnimationType.fromTop,
  isCloseButton: false,
  isOverlayTapDismiss: false,
  descStyle: const TextStyle(fontWeight: FontWeight.bold),
  descTextAlign: TextAlign.start,
  animationDuration: const Duration(milliseconds: 400),
  alertBorder: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(0.0),
    side: const BorderSide(color: Colors.grey),
  ),
  titleStyle: const TextStyle(color: Colors.red),
  alertAlignment: Alignment.topCenter,
);

class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({super.key, required this.overlayColour});

  final Color overlayColour;

  @override
  Widget build(BuildContext context) {
    double scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 200.0
        : 330.0;
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            overlayColour,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: scanArea,
                  width: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            foregroundPainter: BorderPainter(),
            child: SizedBox(
              width: scanArea + 25,
              height: scanArea + 25,
            ),
          ),
        ),
      ],
    );
  }
}

class BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const width = 4.0;
    const radius = 20.0;
    const tRadius = 3 * radius;
    final rect = Rect.fromLTWH(
      width,
      width,
      size.width - 2 * width,
      size.height - 2 * width,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
    final clippingRect0 = Rect.fromLTWH(0, 0, tRadius, tRadius);
    final clippingRect1 =
        Rect.fromLTWH(size.width - tRadius, 0, tRadius, tRadius);
    final clippingRect2 =
        Rect.fromLTWH(0, size.height - tRadius, tRadius, tRadius);
    final clippingRect3 = Rect.fromLTWH(
        size.width - tRadius, size.height - tRadius, tRadius, tRadius);

    final path = Path()
      ..addRect(clippingRect0)
      ..addRect(clippingRect1)
      ..addRect(clippingRect2)
      ..addRect(clippingRect3);

    canvas.clipPath(path);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
