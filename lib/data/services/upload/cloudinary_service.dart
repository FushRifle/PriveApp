import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import './upload_service.dart';

class CloudinaryService {
  final UploadService _uploadService = UploadService();

  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      // Get signature from your backend
      final signatureResponse = await _uploadService.getUploadSignature(
        folder: 'prive-feeds',
        resourceType: 'image',
      );

      if (signatureResponse == null) {
        throw Exception('Failed to get upload signature');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://api.cloudinary.com/v1_1/${signatureResponse['cloudName']}/image/upload'),
      );

      // Add all required fields
      request.fields['api_key'] = signatureResponse['apiKey'];
      request.fields['timestamp'] = signatureResponse['timestamp'].toString();
      request.fields['signature'] = signatureResponse['signature'];
      request.fields['upload_preset'] = signatureResponse['uploadPreset'];
      request.fields['folder'] = signatureResponse['folder'];

      // Add the file
      var fileStream = http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', _getFileExtension(imageFile.path)),
      );
      request.files.add(await fileStream);

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        print('Cloudinary error status: ${response.statusCode}');
        print('Cloudinary error body: $responseBody');
        throw Exception('Upload failed with status: ${response.statusCode}');
      }

      final responseData = json.decode(responseBody);
      return responseData['secure_url'];
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadVideo(File videoFile, String folder) async {
    try {
      // Get signature from your backend
      final signatureResponse = await _uploadService.getUploadSignature(
        folder: folder,
        resourceType: 'video',
      );

      if (signatureResponse == null) {
        throw Exception('Failed to get upload signature');
      }

      // Create multipart request for video
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://api.cloudinary.com/v1_1/${signatureResponse['cloudName']}/video/upload'),
      );

      // Add all required fields
      request.fields['api_key'] = signatureResponse['apiKey'];
      request.fields['timestamp'] = signatureResponse['timestamp'].toString();
      request.fields['signature'] = signatureResponse['signature'];
      request.fields['upload_preset'] = signatureResponse['uploadPreset'];
      request.fields['folder'] = signatureResponse['folder'];
      request.fields['resource_type'] = 'video';

      // Add the file
      var fileStream = http.MultipartFile.fromPath(
        'file',
        videoFile.path,
        contentType: MediaType('video', _getFileExtension(videoFile.path)),
      );
      request.files.add(await fileStream);

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        print('Cloudinary error status: ${response.statusCode}');
        print('Cloudinary error body: $responseBody');
        throw Exception('Upload failed with status: ${response.statusCode}');
      }

      final responseData = json.decode(responseBody);
      return responseData['secure_url'];
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload video: $e');
    }
  }

  String _getFileExtension(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'jpeg';
      case '.png':
        return 'png';
      case '.gif':
        return 'gif';
      case '.webp':
        return 'webp';
      case '.mp4':
        return 'mp4';
      case '.mov':
        return 'mov';
      case '.avi':
        return 'avi';
      default:
        return extension.replaceFirst('.', '');
    }
  }
}
