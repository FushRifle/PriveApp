import 'package:dio/dio.dart';
import '../../clients/api_service.dart';

class UploadService {
  UploadService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<UploadSignature> getUploadSignature({
    required String folder,
    List<String>? tags,
    String resourceType = 'image',
  }) async {
    try {
      final response = await _api.post('/api/upload/sign', data: {
        'folder': folder,
        'tags': tags ?? [],
        'resourceType': resourceType,
      });

      final data = response.data;
      if (data is! Map) throw const FormatException('Invalid upload signature');
      return UploadSignature.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw UploadException(
        _readError(e.response?.data, 'Unable to authorize this upload'),
      );
    } on FormatException {
      throw const UploadException('Invalid upload authorization response');
    }
  }

  Future<void> deleteImage(String publicId) async {
    try {
      await _api.delete('/api/upload/${Uri.encodeComponent(publicId)}');
    } on DioException catch (e) {
      throw UploadException(
        _readError(e.response?.data, 'Failed to delete image'),
      );
    }
  }

  String _readError(dynamic data, String fallback) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return fallback;
  }
}

class UploadSignature {
  const UploadSignature({
    required this.timestamp,
    required this.signature,
    required this.apiKey,
    required this.cloudName,
    required this.uploadPreset,
    required this.folder,
  });

  final int timestamp;
  final String signature;
  final String apiKey;
  final String cloudName;
  final String uploadPreset;
  final String folder;

  factory UploadSignature.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'];
    final result = UploadSignature(
      timestamp: timestamp is int
          ? timestamp
          : int.tryParse(timestamp?.toString() ?? '') ?? 0,
      signature: json['signature']?.toString() ?? '',
      apiKey: json['apiKey']?.toString() ?? '',
      cloudName: json['cloudName']?.toString() ?? '',
      uploadPreset: json['uploadPreset']?.toString() ?? '',
      folder: json['folder']?.toString() ?? '',
    );

    if (result.timestamp <= 0 ||
        result.signature.isEmpty ||
        result.apiKey.isEmpty ||
        result.cloudName.isEmpty ||
        result.uploadPreset.isEmpty ||
        result.folder.isEmpty) {
      throw const FormatException('Incomplete upload signature');
    }
    return result;
  }
}

class UploadException implements Exception {
  const UploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
