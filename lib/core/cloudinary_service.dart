import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dug6225go';
  static const String uploadPreset = 'prive-preset';
  static const String folder = 'prive_feeds';

  Future<String> uploadImage(
    File imageFile, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = customFolder ?? folder;
      request.fields['resource_type'] = 'image';

      var fileStream = http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(await fileStream);

      if (onProgress != null) {
        onProgress(0.3);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress(0.6);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress(0.9);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        print('Cloudinary error: $responseBody');
        throw Exception('Upload failed: ${response.statusCode}');
      }

      if (onProgress != null) onProgress(1.0);

      final responseData = json.decode(responseBody);
      return responseData['secure_url'];
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadVideo(
    File videoFile, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = customFolder ?? folder;
      request.fields['resource_type'] = 'video';

      var fileStream = http.MultipartFile.fromPath('file', videoFile.path);
      request.files.add(await fileStream);

      final response = await request.send();

      int bytesSent = 0;
      if (onProgress != null && response.stream.isBroadcast == false) {
        onProgress(0.5);
      }

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        print('Cloudinary error: $responseBody');
        throw Exception('Upload failed: ${response.statusCode}');
      }

      if (onProgress != null) onProgress(1.0);

      final responseData = json.decode(responseBody);
      return responseData['secure_url'];
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<String> uploadDocument(File documentFile, String fileName) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;
      request.fields['resource_type'] = 'raw';
      request.fields['public_id'] = fileName.split('.').first;

      var fileStream = http.MultipartFile.fromPath('file', documentFile.path);
      request.files.add(await fileStream);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception('Upload failed');
      }

      final responseData = json.decode(responseBody);
      return responseData['secure_url'];
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<bool> deleteFile(String publicId) async {
    try {
      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }
}
