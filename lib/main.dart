import 'dart:async';
//import 'dart:html';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrweb/index/index.dart';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';


import 'package:qrweb/scanner/scanner.dart';
import 'package:qrweb/scanner/scannertest.dart';

// import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ddxpxalpgnrzysxuvmxo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  );

  await Permission.camera.request();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RGS Recovery - Attendance',
      initialRoute: '/test',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/'                   : (context) => const ScannerPage(),
        '/test'               : (context) => const ScannerDevTest(),
        '/attendance'         : (context) => Index(),
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, String host, int port)=> true;
  }
}

// class InAppWebViewPage extends StatefulWidget {
//   @override
//   _InAppWebViewPageState createState() => new _InAppWebViewPageState();
// }
//
// class _InAppWebViewPageState extends State<InAppWebViewPage> {
//   late InAppWebViewController _webViewController;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: Column(children: <Widget>[
//           Expanded(
//             child: InAppWebView(
//                 initialUrlRequest: URLRequest(
//                     url: Uri.parse("https://www.rgsrecovery.com.ph/attendance")
//                   //url: Uri.parse("https://www.scanapp.org")
//                 ),
//                 initialOptions: InAppWebViewGroupOptions(
//                   ios: IOSInAppWebViewOptions(
//                     allowsInlineMediaPlayback: false,
//                   ),
//                   crossPlatform: InAppWebViewOptions(
//                     mediaPlaybackRequiresUserGesture: false,
//                     javaScriptEnabled: true,
//                     javaScriptCanOpenWindowsAutomatically: true,
//                     supportZoom: false,
//                     //debuggingEnabled: true,
//                   ),
//                 ),
//                 onWebViewCreated: (InAppWebViewController controller) {
//                   _webViewController = controller;
//                 },
//                 onReceivedServerTrustAuthRequest: (controller, challenge) async {
//                   return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
//                 },
//                 androidOnPermissionRequest: (InAppWebViewController controller, String origin, List<String> resources) async {
//                   return PermissionRequestResponse(resources: resources, action: PermissionRequestResponseAction.GRANT);
//                 }
//             ),
//           ),
//         ])
//     );
//   }
// }

// initialUrlRequest: URLRequest(
// url: Uri.parse("https://www.rgsrecovery.com.ph/attendance")
// ),
// onReceivedServerTrustAuthRequest: (controller, challenge) async {
// return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// Future main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Permission.camera.request();
//   await Permission.microphone.request();
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//
//     WebViewController controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             // Update loading bar.
//           },
//           onPageStarted: (String url) {},
//           onPageFinished: (String url) {},
//           onWebResourceError: (WebResourceError error) {},
//           onNavigationRequest: (NavigationRequest request) {
//             if (request.url.startsWith('https://www.youtube.com/')) {
//               return NavigationDecision.prevent;
//             }
//             return NavigationDecision.navigate;
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse('https://www.rgsrecovery.com.ph/attendance'));
//     //..loadRequest(Uri.parse('http://rgsrecovery.com.ph/attendance'));
//
//     return MaterialApp(
//       title: 'RGS APPROVAL',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: Scaffold(
//         body: WebViewWidget(controller: controller),
//       ),
//     );
//   }
// }
//
// /*
// Future<void> requestCameraPermission() async {
//   final status = await Permission.camera.request();
//   if (status == PermissionStatus.granted) {
//     // Permission granted.
//   } else if (status == PermissionStatus.denied) {
//     // Permission denied.
//   } else if (status == PermissionStatus.permanentlyDenied) {
//     // Permission permanently denied.
//   }
// }*/
