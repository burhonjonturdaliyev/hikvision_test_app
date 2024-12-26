import 'dart:io';
import 'package:digest_auth/digest_auth.dart';
import 'package:http/http.dart' as http;

class FormDataRpc {
  final String rpcUrl;
  final String username;
  final String password;

  FormDataRpc(this.rpcUrl, {required this.username, required this.password});

  Future<void> sendFormData(Map<String, String> fields, File file) async {
    final http.Client client = http.Client();
    final DigestAuth digestAuth = DigestAuth(username, password);

    // Initial request to get the `WWW-Authenticate` header.
    final initialResponse = await client.post(
      Uri.parse(rpcUrl),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (initialResponse.statusCode != 401 ||
        !initialResponse.headers.containsKey('www-authenticate')) {
      throw Exception('Unexpected response: ${initialResponse.body}');
    }

    // Extract Digest details from `WWW-Authenticate` header.
    final String authInfo = initialResponse.headers['www-authenticate']!;
    digestAuth.initFromAuthorizationHeader(authInfo);

    // Create Authorization header for the second request.
    String uri = Uri.parse(rpcUrl).path;
    String authHeader = digestAuth.getAuthString('POST', uri);

    // Use MultipartRequest to send form-data.
    final request = http.MultipartRequest('POST', Uri.parse(rpcUrl))
      ..headers.addAll({
        'Authorization': authHeader,
      })
      ..fields.addAll(fields)
      ..files.add(await http.MultipartFile.fromPath('FaceImage', file.path));

    final streamedResponse = await client.send(request);

    // Handle the streamed response.
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Form-data submission failed: ${response.body}');
    }

    print('Response: ${response.body}');
  }
}
