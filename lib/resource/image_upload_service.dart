// lib/services/image_upload_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String?> uploadImageToImgbb(File imageFile) async {
  const apiKey = '41fb72f594145b77abf413865905d2cb'; 
  final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

  final base64Image = base64Encode(await imageFile.readAsBytes());

  final response = await http.post(url, body: {
    'image': base64Image,
  });

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data']['url'];
  } else {
    print('Upload failed: ${response.body}');
    return null;
  }
}
