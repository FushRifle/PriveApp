import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dug6225go';
  static const String uploadPreset = 'prive-preset';
  static const String folder = 'prive_feeds';

  Future<String> uploadImage(File imageFile, [String? folder]) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder!;
      request.fields['resource_type'] = 'image';

      var fileStream = http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(await fileStream);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        print('Cloudinary error: $responseBody');
        throw Exception('Upload failed');
      }

      final responseData = json.decode(responseBody);
      return responseData['secure_url'];
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload image');
    }
  }

  Future<String> uploadVideo(File videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      request.fields['resource_type'] = 'video';

      var fileStream = http.MultipartFile.fromPath('file', videoFile.path);
      request.files.add(await fileStream);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        print('Cloudinary error: $responseBody');
        throw Exception('Upload failed');
      }

      final responseData = json.decode(responseBody);
      return responseData['secure_url'];
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload video');
    }
  }
}
