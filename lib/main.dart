import 'dart:io';

import 'package:hikvision_test_app/function.dart';

void main() async {
  final formDataRpc = FormDataRpc(
    'http://192.168.1.100/ISAPI/Intelligent/FDLib/FaceDataRecord?format=json',
    username: 'admin', // Replace with your username.
    password: 'abc@1234', // Replace with your password.
  );

  final file =
      File('assets/sodiqjon.jpg'); // Replace with your image file path.

  try {
    await formDataRpc.sendFormData(
      {
        'FaceDataRecord': '{"faceLibType":"blackFD","FPID":"44"}',
      },
      file,
    );
  } catch (e) {
    print('Error: $e');
  }
}
