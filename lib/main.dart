import 'dart:io';

import 'package:hikvision_test_app/function.dart';

void main() async {
  final file =
      File('assets/sodiqjon.jpg'); // Replace with your image file path.

  try {
    await UserControlFunction().postFile(file);
  } catch (e) {
    print('Error: $e');
  }
}
