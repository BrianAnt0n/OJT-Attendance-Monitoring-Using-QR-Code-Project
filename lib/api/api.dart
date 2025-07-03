import 'dart:convert';
import 'dart:typed_data';
//import 'dart:io';
import 'package:flutter/foundation.dart';
//import 'package:universal_io/io.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// POST QR
Future<QRDetails> postQR(
    String qrCodeValue, String imageName, Uint8List compressedImage) async {
  // Set up API Endpoint
  QRDetails details = QRDetails();

  //XAMPPP insert php json
  String url = 'http://localhost/qrweb-main/lib/api/db_connect.php';

  var client = http.MultipartRequest('POST', Uri.parse(url));
  var multipartFile = http.MultipartFile.fromBytes('imgInOut', compressedImage,
      contentType: MediaType.parse('image/jpg'), filename: 'imgInOut.jpg');
  //Attendance coilumn
  client.fields['employeeid'] = qrCodeValue;

  //
  client.files.add(multipartFile);
  client.headers['Access-Control-Allow-Origin'] = "*";
  client.headers['X-Requested-With'] = "XMLHttpRequest";

  //debugPrint('APITest - Before Sending');

  //debugPrint('Added to multipart');
  var response = await client.send();

  //debugPrint('APITest - After Sending');

  String jsonToDecode = await response.stream.bytesToString();

  //debugPrint('APITest - JSON To Decode: $jsonToDecode');
  //debugPrint('APITest - Before decoding');

  Map<String, dynamic> value = jsonDecode(jsonToDecode);

  //debugPrint('APITest - After decoding');

  details.success = value['success'];
  details.message = value['message'];
  details.employeeId = value['employeeID'];
  details.fullname = value['fullname'];
  details.error = value['error'];

  // debugPrint('APITest - Success: ${details.success}');
  // debugPrint('APITest - Message: ${details.message}');
  // debugPrint('APITest - Employee ID: ${details.employeeId}');
  // debugPrint('APITest - Full Name: ${details.fullname}');
  // debugPrint('APITest - Error: ${details.error}');

  return details;
}

class QRDetails {
  QRDetails(
      {this.success, this.message, this.employeeId, this.fullname, this.error});
  String? success;
  String? message;
  String? employeeId;
  String? fullname;
  String? error;
}

// // https://stackoverflow.com/questions/69415505/flutter-dio-library-xmlhttprequest-error-web
// try{
// var client = http.MultipartRequest('POST', Uri.parse(url));
// var multipartFile = http.MultipartFile.fromBytes('imgInOut', compressedImage,
// contentType: MediaType.parse('image/jpg'), filename: 'imgInOut.jpg');
// client.fields['qrcode'] = qrCodeValue;
// client.files.add(multipartFile);
// client.headers['Access-Control-Allow-Origin'] = "*";
// client.headers['X-Requested-With'] = "XMLHttpRequest";
//
// //debugPrint('Added to multipart');
// var response = await client.send();
//
// String jsonToDecode = await response.stream.bytesToString();
//
// Map<String, dynamic> value = jsonDecode(jsonToDecode);
//
// details.success = value['success'];
// details.message = value['message'];
// details.employeeId = value['employeeID'];
// details.fullname = value['fullname'];
// details.error = value['error'];
// }
// on Exception catch (e){
// if (e is http.ClientException && e.message == "XMLHttpRequest error.") {
// //debugPrint("CORS error.");
// }
// //debugPrint('Exception: $e');
// }
// finally {
// //debugPrint('API End');
// }
