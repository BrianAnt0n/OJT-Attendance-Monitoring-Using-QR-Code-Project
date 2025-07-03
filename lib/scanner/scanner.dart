import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrweb/api/api.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';


void main() => runApp(const MaterialApp(home: ScannerPage()));

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
      minHeight: 640,
      minWidth: 480,
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
    formats: [
      BarcodeFormat.qrCode
    ]
  );

  void onQRDetect(BarcodeCapture capture) async {
    if (!isDisplayed) {
      setState(() {
        isDisplayed = true;
      });
      bool result = false;
      if (kIsWeb){
        result = true;
      } else {
        result = await InternetConnectionChecker().hasConnection;
      }
      if (result == true) {
        final List<Barcode> barcodes = capture.barcodes;

        // Save Image
        final webImage = await cameraController.takePicture();
        Uint8List image = await webImage.readAsBytes();

        Uint8List compressedImage = await compressImage(image);

        if (barcodes.isNotEmpty){
          try {
            QRDetails response =
            await postQR('${barcodes[0].rawValue}', imageName, image);
            // debugPrint('Success: ${response.success}');
            // debugPrint('Message: ${response.message}');
            // debugPrint('employeeId: ${response.employeeId}');
            // debugPrint('Fullname: ${response.fullname}');
            // debugPrint('Error: ${response.error}');

            if (response.message == null) {
              showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Server Error',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25),
                        ),
                      ],
                    ),
                    content: Text(
                      'Please contact your administrator.',
                      style: TextStyle(fontSize: 20),
                    ),
                  )).timeout(
                  const Duration(seconds: 2),
                  onTimeout: () {
                    setState(() {
                      isDisplayed = false;
                    });
                    Navigator.pop(context);
                  }
              );
            }
            else if (response.message == 'Invalid QR Code!') {
              //debugPrint('E: IQC - ${barcodes[0].rawValue}');
              showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Invalid QR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25),
                        ),
                      ],
                    ),
                    content: Text(
                      'Please present a valid QR Code and try again.',
                      style: TextStyle(fontSize: 20),
                    ),
                  ))
                  .timeout(
                  const Duration(seconds: 2),
                  onTimeout: () {
                    setState(() {
                      isDisplayed = false;
                    });
                    Navigator.pop(context);
                  }
              );
            }
            if (response.success != null) {
              String headerText =
              (response.message == 'timeIn') ? 'Time In' : 'Time Out';

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                    content: SizedBox(
                      height: 420,
                      child: Center(
                        child: RotationTransition(
                            turns: const AlwaysStoppedAnimation(0 / 360),
                            child: Image.memory(compressedImage,
                                width: 350,
                                height:
                                550) //Image(image: MemoryImage(image), width: 550, height: 950),
                        ),
                      ),
                    ),
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Container()),
                            Text(
                              headerText,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25),
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        Text(
                          '${response.fullname}',
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(height: 10),
                        Text('Employee ID: ${response.employeeId}'),
                        const SizedBox(height: 10),
                        Text(
                          DateFormat.MMMMEEEEd().format(DateTime.now()),
                          style: const TextStyle(
                              color: Colors.black26,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text(
                          DateFormat('hh:mm').format(DateTime.now()),
                          style: const TextStyle(
                              color: Colors.black26,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                      ],
                    )),
              ).timeout(
                  const Duration(seconds: 2),
                  onTimeout: () {
                    setState(() {
                      isDisplayed = false;
                    });
                    Navigator.pop(context);
                  }
              );
            // end of if(image != null)
            } // end of if statement
          } on Exception catch (_) {
            showDialog(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Server Error',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                    ],
                  ),
                  content: Text(
                    'Please contact your administrator.',
                    style: TextStyle(fontSize: 20),
                  ),
                )).timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  setState(() {
                    isDisplayed = false;
                  });
                  Navigator.pop(context);
                }
            );
            rethrow;
          }
        }
      } else {
        showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Internet Not Detected',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                ],
              ),
              content: Text(
                'Please connect to a stable internet connection and try again.',
                style: TextStyle(fontSize: 20),
              ),
            )).timeout(const Duration(seconds: 2)).whenComplete(() {
          setState(() {
            isDisplayed = false;
          });
          Navigator.pop(context);
        });
      }
    }
  }

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  late List<CameraDescription> cameras;
  late CameraController cameraController;

  @override
  void initState() {
    startCamera();
    super.initState();
  }

  void startCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false
    );
    await cameraController.initialize().then((value){
      if(!mounted){
        return;
      }
      setState(() {});// To refresh widget
      
    }).catchError((e){
      //u('Camera Error: $e');
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: Column(children: <Widget>[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 30),
              const Image(
                image: AssetImage('assets/rgslogo1024.png'),
                height: 140,
                width: 140,
              ),
              Expanded(child: _clockWidget(context)),
              const SizedBox(
                width: 30,
              ),
            ],
          ),

           Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 30),
              const Image(
                image: AssetImage('assets/rgsborder.png'),
                height: 140,
                width: 140,
              ),
              Expanded(child: _clockWidget(context)),
              const SizedBox(
                width: 30,
              ),
            ],
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
                        //debugPrint('QR Detected');
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
                              fontSize: 30,
                              //fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )),
        ]),
      );
    }
    catch(e) {
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
                color: Colors.black26,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          Text(
            DateFormat('hh:mm:ss').format(DateTime.now()),
            style: const TextStyle(
                color: Colors.black26,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
        ],
      );
      //return Text(DateFormat('MMMM DD yyyy hh:mm:ss').format(DateTime.now()));
    },///////
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
