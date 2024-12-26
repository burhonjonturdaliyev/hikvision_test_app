import 'dart:convert';
import 'dart:developer';

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

// To handle file paths

class UserControlFunction {
  String _md5(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Map<String, String> _parseAuthenticateHeader(String header) {
    final regex = RegExp(r'(\w+)="([^"]+)"');
    final matches = regex.allMatches(header);
    final Map<String, String> params = {};
    for (final match in matches) {
      params[match.group(1)!] = match.group(2)!;
    }
    return params;
  }

  Future<void> postFile(File faceImageFile) async {
    const uri =
        "http://192.168.1.100/ISAPI/Intelligent/FDLib/FaceDataRecord?format=json"; // Replace with your actual API URL
    final url = Uri.parse(uri);

    // Check if the file exists and is not empty
    if (!(await faceImageFile.exists())) {
      log("File does not exist: ${faceImageFile.path}");
      return;
    }

    log(faceImageFile.path);

    final fileLength = await faceImageFile.length();
    if (fileLength == 0) {
      log("File is empty and will not be uploaded: ${faceImageFile.path}");
      return;
    }

    // Step 1: Send an unauthenticated POST request to get the nonce
    final response = await http.post(url);

    if (response.statusCode == 401) {
      final authHeader = response.headers['www-authenticate'];
      if (authHeader != null) {
        // Parse the `WWW-Authenticate` header to extract parameters
        final parts = _parseAuthenticateHeader(authHeader);

        final ha1 = _md5('admin:${parts['realm']}:abc@1234');
        final ha2 = _md5('POST:${parts['uri']}');
        final responseDigest = _md5('$ha1:${parts['nonce']}:$ha2');

        final authValue = 'Digest username="admin", '
            'realm="${parts['realm']}", '
            'nonce="${parts['nonce']}", '
            'uri="${parts['uri']}", '
            'response="$responseDigest"';

        final request = http.MultipartRequest('POST', url);

        // Add the Authorization header
        request.headers['Authorization'] = authValue;
        log(authValue);

        // Add the multipart form fields and the file
        request.fields['FaceDataRecord'] =
            '{"faceLibType":"blackFD","FDID":"2","FPID":"18"}';

        var multipartFile =
            await http.MultipartFile.fromPath('FaceImage', faceImageFile.path);
        request.files.add(multipartFile);

        // Send the request
        var response = await request.send();

        // Await the response stream to get the actual content
        final responseBody = await response.stream.bytesToString();

        log('Status Code: ${response.statusCode}');
        log('Response Body: $responseBody');
      } else {
        log('Authorization header not found in server response.');
      }
    } else {
      log('Failed to get nonce, status: ${response.statusCode}');
      log('Response body: ${response.body}');
    }
  }
}
