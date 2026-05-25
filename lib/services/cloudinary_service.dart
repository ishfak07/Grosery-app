import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dbflkn1ig';
  static const String uploadPreset = 'grocery_unsigned';

  static Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'grocery_app'
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final secureUrl = data['secure_url'];

      if (secureUrl == null || secureUrl.toString().isEmpty) {
        throw Exception(
            'Cloudinary upload succeeded but secure_url is missing');
      }

      return secureUrl.toString();
    } else {
      throw Exception(
        'Cloudinary upload failed: ${response.statusCode} - $responseBody',
      );
    }
  }
}
