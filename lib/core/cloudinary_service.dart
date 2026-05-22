import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String cloudName = 'dug6225go';
  static const String uploadPreset = 'prive-preset';
  static const String folder = 'prive_feeds';
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Map<String, int> sizeLimits = {
    'image': 10,
    'video': 100,
    'audio': 25,
    'document': 15,
  };

  static const Map<String, List<String>> supportedFormats = {
    'image': [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
    ],
    'video': [
      'mp4',
      'mov',
      'avi',
      'wmv',
      'flv',
      'mkv',
    ],
    'audio': [
      'mp3',
      'wav',
      'aac',
      'ogg',
      'm4a',
      'flac',
    ],
    'document': [
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ],
  };

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  final Map<String, CancelToken> _uploadTokens = {};

  // =========================================================
  // IMAGE
  // =========================================================

  Future<String> uploadImage(
    File file, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    return _uploadWithRetry(
      file: file,
      type: 'image',
      resourceType: 'image',
      customFolder: customFolder,
      onProgress: onProgress,
    );
  }

  // =========================================================
  // VIDEO
  // =========================================================

  Future<String> uploadVideo(
    File file, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    return _uploadWithRetry(
      file: file,
      type: 'video',
      resourceType: 'video',
      customFolder: customFolder,
      onProgress: onProgress,
    );
  }

  // =========================================================
  // AUDIO
  // =========================================================

  Future<String> uploadAudio(
    File file, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    return _uploadWithRetry(
      file: file,
      type: 'audio',
      resourceType: 'raw',
      customFolder: customFolder,
      onProgress: onProgress,
    );
  }

  // =========================================================
  // DOCUMENT
  // =========================================================

  Future<String> uploadDocument(
    File file,
    String fileName, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    return _uploadWithRetry(
      file: file,
      type: 'document',
      resourceType: 'raw',
      customFolder: customFolder,
      onProgress: onProgress,
      publicId: fileName.split('.').first,
    );
  }

  // =========================================================
  // RETRY
  // =========================================================

  Future<String> _uploadWithRetry({
    required File file,
    required String type,
    required String resourceType,
    String? customFolder,
    Function(double)? onProgress,
    String? publicId,
  }) async {
    await validateFile(file, type);

    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await _performUpload(
          file: file,
          type: type,
          resourceType: resourceType,
          customFolder: customFolder,
          onProgress: onProgress,
          publicId: publicId,
        );
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          rethrow;
        }

        await Future.delayed(
          Duration(seconds: attempts),
        );
      }
    }

    throw Exception('Upload failed');
  }

  // =========================================================
  // MAIN UPLOAD
  // =========================================================

  Future<String> _performUpload({
    required File file,
    required String type,
    required String resourceType,
    String? customFolder,
    Function(double)? onProgress,
    String? publicId,
  }) async {
    final endpoint =
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';

    final tokenKey = '${file.path}_${DateTime.now().millisecondsSinceEpoch}';

    final cancelToken = CancelToken();

    _uploadTokens[tokenKey] = cancelToken;

    try {
      final mime = _getMimeType(file.path);

      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
        contentType: mime != null ? MediaType.parse(mime) : null,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'upload_preset': uploadPreset,
        'folder': customFolder ?? folder,
        if (publicId != null) 'public_id': publicId,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (onProgress == null || total <= 0) return;

          final progress = sent / total;

          onProgress(progress.clamp(0.0, 1.0));
        },
      );

      final data = response.data;

      if (data == null || data['secure_url'] == null) {
        throw Exception('Invalid upload response');
      }

      return data['secure_url'].toString();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Upload cancelled');
      }

      final error = e.response?.data;

      if (error is Map && error['error'] != null) {
        throw Exception(
          error['error']['message'] ?? 'Upload failed',
        );
      }

      throw Exception('Upload failed');
    } finally {
      _uploadTokens.remove(tokenKey);
    }
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  Future<void> validateFile(
    File file,
    String type,
  ) async {
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    final size = await file.length();

    if (size <= 0) {
      throw Exception('File is empty');
    }

    final sizeMB = size / (1024 * 1024);

    final limit = sizeLimits[type] ?? 25;

    if (sizeMB > limit) {
      throw Exception(
        'File exceeds ${limit}MB limit',
      );
    }

    final extension = file.path.split('.').last.toLowerCase();

    final formats = supportedFormats[type];

    if (formats == null || !formats.contains(extension)) {
      throw Exception(
        'Unsupported $type format: $extension',
      );
    }
  }

  // =========================================================
  // CANCEL
  // =========================================================

  void cancelAllUploads() {
    for (final token in _uploadTokens.values) {
      token.cancel();
    }

    _uploadTokens.clear();
  }

  // =========================================================
  // MIME
  // =========================================================

  String? _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();

    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'gif':
        return 'image/gif';

      case 'webp':
        return 'image/webp';

      case 'mp4':
        return 'video/mp4';

      case 'mov':
        return 'video/quicktime';

      case 'mp3':
        return 'audio/mpeg';

      case 'wav':
        return 'audio/wav';

      case 'pdf':
        return 'application/pdf';

      case 'doc':
        return 'application/msword';

      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'txt':
        return 'text/plain';

      default:
        return null;
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  static Future<double> getFileSizeInMB(
    File file,
  ) async {
    final size = await file.length();

    return size / (1024 * 1024);
  }

  static bool isFormatSupported(
    String path,
    String type,
  ) {
    final ext = path.split('.').last.toLowerCase();

    return supportedFormats[type]?.contains(ext) ?? false;
  }

  static String getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();

    for (final entry in supportedFormats.entries) {
      if (entry.value.contains(ext)) {
        return entry.key;
      }
    }

    return 'unknown';
  }

  static String generateTransformedUrl(
    String url,
    Map<String, String> transformations,
  ) {
    final uri = Uri.parse(url);

    final parts = uri.path.split('/');

    final uploadIndex = parts.indexWhere((e) => e == 'upload');

    if (uploadIndex == -1) {
      return url;
    }

    final transformation =
        transformations.entries.map((e) => '${e.key}_${e.value}').join(',');

    parts.insert(uploadIndex + 1, transformation);

    return uri
        .replace(
          path: parts.join('/'),
        )
        .toString();
  }
}

extension CloudinaryExtensions on CloudinaryService {
  Future<String> uploadWithAutoType(
    File file, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    final type = CloudinaryService.getFileType(file.path);

    switch (type) {
      case 'image':
        return uploadImage(
          file,
          customFolder: customFolder,
          onProgress: onProgress,
        );

      case 'video':
        return uploadVideo(
          file,
          customFolder: customFolder,
          onProgress: onProgress,
        );

      case 'audio':
        return uploadAudio(
          file,
          customFolder: customFolder,
          onProgress: onProgress,
        );

      case 'document':
        return uploadDocument(
          file,
          file.path.split('/').last,
          customFolder: customFolder,
          onProgress: onProgress,
        );

      default:
        throw Exception(
          'Unsupported file type',
        );
    }
  }
}
