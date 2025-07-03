// ignore_for_file: override_on_non_overriding_member, prefer_const_constructors, use_build_context_synchronously, unused_import, prefer_const_declarations

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrweb/api/api.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:convert'; // For encoding JSON
import 'package:flutter_image_compress/flutter_image_compress.dart';

void main() => runApp(const MaterialApp(home: ScannerPage()));

Future<void> scanAndInsert(String employeeId) async {
  final url = Uri.parse(
      'http://localhost/qrweb-main/lib/api/insert.php'); // URL to your insert.php
  final response = await http.post(
    url,
    body: {
      'employeeid':
          employeeId, // This should match the expected input in insert.php
    },
  );

  if (response.statusCode == 200) {
    print('Insert successful');
  } else {
    print('Failed to insert: ${response.statusCode}');
  }
}

Future<void> sendQRData(String qrData) async {
  final url = 'http://localhost/qrweb-main/lib/api/api.dart'; //API URL
  final response = await http.post(
    Uri.parse(url),
    body: {
      'employeeid': qrData, // Assuming qrData contains the employee ID
    },
  );
  if (response.statusCode == 200) {
    print('QR data sent successfully: ${response.body}');
  } else {
    print('Failed to send QR data: ${response.statusCode}');
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerTestState();
}

class _ScannerTestState extends State<ScannerPage> {
  bool isDisplayed = false;

  String imageName = '';
  String imageFilePath = '';

  Future<Uint8List> compressImage(Uint8List img) async {
    //debugPrint('Compress Image');
    var result = await FlutterImageCompress.compressWithList(
      img,
      minHeight: 540,
      minWidth: 380,
      quality: 30,
      rotate: 0,
    );
    //debugPrint('Compressed Image: ${img.length}');
    //debugPrint('Compressed Result: ${result.length}');
    return result;
  }

  MobileScannerController scannerController = MobileScannerController(
      facing: CameraFacing.front,
      torchEnabled: false,
      returnImage: true,
      detectionTimeoutMs: 1000, //1 second
      formats: [BarcodeFormat.qrCode]);

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
          String employeeId = barcodes[0].rawValue ?? '';
          print("Detected Employee ID: $employeeId"); // Debugging

          // Step 1: Validate the employee ID and get full name
          Map<String, dynamic> validationData =
              await validateEmployeeId(employeeId);
          bool isValidEmployee = validationData['isValid'];
          String fullName = validationData['fullName'];

          if (isValidEmployee) {
            // Employee ID found, proceed with time in/out
            await executeTimeInOut(employeeId);

            // Show success dialog with full name
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Center(child: Text('Employee Verified')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.memory(
                      compressedImage,
                      width: 200,
                      height: 200,
                    ),
                    SizedBox(height: 10),
                    Text('Full Name: $fullName'), // Display full name
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
  Future<Map<String, dynamic>> validateEmployeeId(String employeeId) async {
    final url =
        Uri.parse('http://localhost/qrweb-main/lib/api/validate_employee.php');
    final response = await http.post(
      url,
      body: {'employeeid': employeeId}, // Ensure key matches PHP expectations
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Validation Response: $data'); // Debugging
      return {'isValid': data['isValid'], 'fullName': data['fullName']};
    } else {
      print('Failed to validate employee ID: ${response.statusCode}');
      return {'isValid': false, 'fullName': ''};
    }
  }

// Step 2: Execute time in/out by sending a POST request to insert.php
  Future<void> executeTimeInOut(String employeeId) async {
    final url = Uri.parse('http://localhost/qrweb-main/lib/api/insert.php');
    final response = await http.post(
      url,
      body: {'employeeid': employeeId}, // Consistent key with PHP script
    );

    if (response.statusCode == 200) {
      print('Time in/out recorded successfully');
    } else {
      print('Failed to record time in/out: ${response.statusCode}');
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Initialization'),
            content: const Text('TIME IN!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  void startCamera() async {
    cameras = await availableCameras();
    cameraController =
        CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
    await cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {}); // To refresh widget
    }).catchError((e) {
      //u('Camera Error: $e');
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  bool isButton1Active = true; // time in is initially active
  bool isButton2Active = false; // time out is inactive
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
                      });
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Alert'),
                            content: Text('TIME IN!'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );
                      //  button 1
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
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Alert'),
                            content: Text('TIME OUT!'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );
                      //debugPrint('Time out');
                      setState(() {
                        isButton2Active = true; // Activate Button 2
                        isButton1Active = false; // Deactivate Button 1
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
                color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('hh:mm:ss').format(DateTime.now()),
            style: const TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      );
      //return Text(DateFormat('MMMM DD yyyy hh:mm:ss').format(DateTime.now()));
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
    side: const BorderSide(
      color: Colors.grey,
    ),
  ),
  titleStyle: const TextStyle(
    color: Colors.red,
  ),
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
    return Stack(children: [
      ColorFiltered(
        colorFilter: ColorFilter.mode(
            overlayColour, BlendMode.srcOut), // This one will create the magic
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                  color: Colors.red,
                  backgroundBlendMode: BlendMode
                      .dstOut), // This one will handle background + difference out
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
    ]);
  }
}

// Creates the white borders
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
    const clippingRect0 = Rect.fromLTWH(
      0,
      0,
      tRadius,
      tRadius,
    );
    final clippingRect1 = Rect.fromLTWH(
      size.width - tRadius,
      0,
      tRadius,
      tRadius,
    );
    final clippingRect2 = Rect.fromLTWH(
      0,
      size.height - tRadius,
      tRadius,
      tRadius,
    );
    final clippingRect3 = Rect.fromLTWH(
      size.width - tRadius,
      size.height - tRadius,
      tRadius,
      tRadius,
    );

    final path = Path()
      ..addRect(clippingRect0)
      ..addRect(clippingRect1)
      ..addRect(clippingRect2)
      ..addRect(clippingRect3);

    canvas.clipPath(path);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class BarReaderSize {
  static double width = 200;
  static double height = 200;
}

class OverlayWithHolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          Path()
            ..addOval(Rect.fromCircle(
                center: Offset(size.width - 44, size.height - 44), radius: 40))
            ..close(),
        ),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

@override
bool shouldRepaint(CustomPainter oldDelegate) {
  return false;
}
