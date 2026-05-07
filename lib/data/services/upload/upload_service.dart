import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:Prive/data/services/api_service.dart';

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;

  final ApiService _apiService = ApiService();

  UploadService._internal();

  // Get signature from backend
  Future<SignatureResponse?> _getSignature(
      String folder, String resourceType) async {
    try {
      final response = await _apiService.post(
        '/api/upload/sign',
        data: {
          'folder': folder,
          'resourceType': resourceType,
        },
      );

      print('Signature response: ${response.statusCode}');
      print('Signature data: ${response.data}');

      if (response.statusCode == 200) {
        return SignatureResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error getting signature: $e');
      return null;
    }
  }

  // Upload file
  Future<CloudinaryResponseModel?> uploadFile({
    required XFile file,
    required String folder,
    String resourceType = 'image',
    Function(double)? onProgress,
  }) async {
    try {
      // Get signature from backend with resourceType
      final signature = await _getSignature(folder, resourceType);
      if (signature == null) {
        throw Exception('Failed to get upload signature');
      }

      print('Signature received. Uploading to Cloudinary...');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://api.cloudinary.com/v1_${signature.cloudName}/$resourceType/upload'),
      );

      // Add all required fields - MUST match what was signed
      request.fields['api_key'] = signature.apiKey;
      request.fields['timestamp'] = signature.timestamp.toString();
      request.fields['signature'] = signature.signature;
      request.fields['folder'] = signature.folder;
      request.fields['upload_preset'] = signature.uploadPreset;
      request.fields['resource_type'] = resourceType;

      // Add the file
      final fileBytes = await file.readAsBytes();
      final extension = resourceType == 'image' ? 'jpg' : 'mp4';
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename:
            '${resourceType}_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      print('Cloudinary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Upload successful. URL: ${data['secure_url']}');
        return CloudinaryResponseModel(
          url: data['secure_url'],
          publicId: data['public_id'],
          width: data['width'],
          height: data['height'],
          format: data['format'],
          resourceType: resourceType,
          size: data['bytes'],
          duration: data['duration'],
          thumbnailUrl: resourceType == 'video' ? data['thumbnail_url'] : null,
        );
      } else {
        print('Upload failed: ${data['error']?['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // Upload image
  Future<CloudinaryResponseModel?> uploadImage({
    required XFile image,
    String? folder,
    Function(double)? onProgress,
  }) async {
    return uploadFile(
      file: image,
      folder: folder ?? 'feeds',
      resourceType: 'image',
      onProgress: onProgress,
    );
  }

  // Upload video
  Future<CloudinaryResponseModel?> uploadVideo({
    required XFile video,
    String? folder,
    Function(double)? onProgress,
  }) async {
    return uploadFile(
      file: video,
      folder: folder ?? 'feeds',
      resourceType: 'video',
      onProgress: onProgress,
    );
  }

  // Delete file
  Future<bool> deleteFile(String publicId) async {
    try {
      final response = await _apiService.delete('/upload/$publicId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}

// Response Models
class SignatureResponse {
  final int timestamp;
  final String signature;
  final String apiKey;
  final String cloudName;
  final String uploadPreset;
  final String folder;

  SignatureResponse({
    required this.timestamp,
    required this.signature,
    required this.apiKey,
    required this.cloudName,
    required this.uploadPreset,
    required this.folder,
  });

  factory SignatureResponse.fromJson(Map<String, dynamic> json) {
    return SignatureResponse(
      timestamp: json['timestamp'],
      signature: json['signature'],
      apiKey: json['apiKey'],
      cloudName: json['cloudName'],
      uploadPreset: json['uploadPreset'],
      folder: json['folder'],
    );
  }
}

class CloudinaryResponseModel {
  final String url;
  final String publicId;
  final int? width;
  final int? height;
  final String? format;
  final String? resourceType;
  final int? size;
  final double? duration;
  final String? thumbnailUrl;

  CloudinaryResponseModel({
    required this.url,
    required this.publicId,
    this.width,
    this.height,
    this.format,
    this.resourceType,
    this.size,
    this.duration,
    this.thumbnailUrl,
  });
}
