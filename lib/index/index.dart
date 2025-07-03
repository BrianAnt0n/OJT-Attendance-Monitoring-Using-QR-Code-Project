import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:screenshot/screenshot.dart';

class Index extends StatelessWidget {
  Index({super.key});

  MobileScannerController scannerController = MobileScannerController(
    facing: CameraFacing.front,
    torchEnabled: false,
    returnImage: true,
  );
  
  final Widget _mobileScanner = MobileScanner(
    fit: BoxFit.contain,
    controller: MobileScannerController(
      facing: CameraFacing.front,
      torchEnabled: false,
      returnImage: true,
    ),
    onDetect: (capture) async {},
  );
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Screenshot(
                controller: _screenshotController,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: _mobileScanner
                    ),

                    const Center(child: Text('TESTTESTTESTTESTTESTTEST'))
                  ],
                )),
          ),
          ElevatedButton(
            child: const Text("Save image"),
            onPressed: () async {
              Uint8List? image = await _screenshotController.capture();
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                      content: SizedBox(
                        height: 420,
                        child: Center(
                          child: RotationTransition(
                              turns: const AlwaysStoppedAnimation(90 / 360),
                              child: Image.memory(image!,
                                  width: 350,
                                  height:
                                  550)
                          ),
                        ),
                      )
                  )
              );
            },
          ),
          ElevatedButton(
            child: const Text("Request permission"),
            onPressed: () async {
              final perm = await html.window.navigator.permissions!.query({"name": "camera"});
              if (perm.state == "denied") {
                Fluttertoast.showToast(
                  msg: "Oops! Camera permission denied.",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.greenAccent,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
                return;
              }
              final stream = await html.window.navigator.getUserMedia(video: true);
              Navigator.of(context).popAndPushNamed('/attendance');
            },
          )
        ],
      ),
    );
  }
}
