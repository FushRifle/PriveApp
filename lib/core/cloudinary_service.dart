import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String cloudName = 'dug6225go';
  static const String uploadPreset = 'prive-preset';
  static const String folder = 'prive_feeds';

  // Configuration for retry logic
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // File size limits (in MB)
  static const Map<String, int> sizeLimits = {
    'image': 10,
    'video': 100,
    'audio': 25,
    'document': 15,
  };

  // Supported formats
  static const Map<String, List<String>> supportedFormats = {
    'image': ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    'video': ['mp4', 'mov', 'avi', 'wmv', 'flv', 'mkv'],
    'audio': ['mp3', 'wav', 'aac', 'ogg', 'm4a', 'flac'],
    'document': [
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'xls',
      'xlsx',
      'ppt',
      'pptx'
    ],
  };

  // ==================== PUBLIC UPLOAD METHODS ====================

  Future<String> uploadImage(
    File imageFile, {
    String? customFolder,
    Function(double)? onProgress,
    Map<String, String>? transformationParams,
  }) async {
    return _uploadWithRetry(
      file: imageFile,
      resourceType: 'image',
      customFolder: customFolder,
      onProgress: onProgress,
      transformationParams: transformationParams,
    );
  }

  Future<String> uploadVideo(
    File videoFile, {
    String? customFolder,
    Function(double)? onProgress,
    Map<String, String>? transformationParams,
  }) async {
    return _uploadWithRetry(
      file: videoFile,
      resourceType: 'video',
      customFolder: customFolder,
      onProgress: onProgress,
      transformationParams: transformationParams,
    );
  }

  Future<String> uploadAudio(
    File audioFile, {
    String? customFolder,
    Function(double)? onProgress,
    Map<String, String>? transformationParams,
  }) async {
    // Validate audio format
    final extension = audioFile.path.split('.').last.toLowerCase();
    if (!supportedFormats['audio']!.contains(extension)) {
      throw Exception(
          'Unsupported audio format: $extension. Supported: ${supportedFormats['audio']!.join(', ')}');
    }

    return _uploadWithRetry(
      file: audioFile,
      resourceType: 'raw',
      customFolder: customFolder,
      onProgress: onProgress,
      transformationParams: transformationParams,
      isAudio: true,
    );
  }

  Future<String> uploadDocument(
    File documentFile,
    String fileName, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    // Validate document format
    final extension = fileName.split('.').last.toLowerCase();
    if (!supportedFormats['document']!.contains(extension)) {
      throw Exception(
          'Unsupported document format: $extension. Supported: ${supportedFormats['document']!.join(', ')}');
    }

    return _uploadWithRetry(
      file: documentFile,
      resourceType: 'raw',
      customFolder: customFolder,
      onProgress: onProgress,
      customPublicId: fileName.split('.').first,
    );
  }

  // ==================== DELETE METHODS ====================

  Future<bool> deleteFile(String publicId,
      {String resourceType = 'image'}) async {
    try {
      // For production, implement actual Cloudinary delete API
      // This requires authentication with API key and secret
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // You'll need to implement signature generation
      // final signature = _generateSignature(publicId, timestamp);

      // Placeholder for actual implementation
      print('Delete requested for: $publicId (type: $resourceType)');

      // Mock successful deletion for now
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  // ==================== VALIDATION METHODS ====================

  Future<void> validateFile(File file, String type) async {
    // Check file size
    final size = await file.length();
    final sizeInMB = size / (1024 * 1024);
    final maxSize = sizeLimits[type] ?? 25;

    if (sizeInMB > maxSize) {
      throw Exception(
          'File too large: ${sizeInMB.toStringAsFixed(2)}MB. Maximum: ${maxSize}MB');
    }

    // Check if file exists
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    // Check if file is empty
    if (size == 0) {
      throw Exception('File is empty');
    }
  }

  // ==================== PRIVATE METHODS ====================

  Future<String> _uploadWithRetry({
    required File file,
    required String resourceType,
    String? customFolder,
    Function(double)? onProgress,
    Map<String, String>? transformationParams,
    String? customPublicId,
    bool isAudio = false,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        // Validate file before upload
        final type = resourceType == 'raw'
            ? (isAudio ? 'audio' : 'document')
            : resourceType;
        await validateFile(file, type);

        // Perform upload
        final result = await _performUpload(
          file: file,
          resourceType: resourceType,
          customFolder: customFolder,
          onProgress: onProgress,
          transformationParams: transformationParams,
          customPublicId: customPublicId,
          isAudio: isAudio,
        );

        return result;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;

        if (attempt < maxRetries && onProgress != null) {
          // Update progress for retry attempt
          onProgress(0.1 * attempt);
          await Future.delayed(retryDelay * attempt);
        }
      }
    }

    throw Exception('Upload failed after $maxRetries attempts: $lastError');
  }

  Future<String> _performUpload({
    required File file,
    required String resourceType,
    String? customFolder,
    Function(double)? onProgress,
    Map<String, String>? transformationParams,
    String? customPublicId,
    bool isAudio = false,
  }) async {
    // Determine the correct endpoint
    String endpoint;
    if (resourceType == 'raw') {
      endpoint = 'raw/upload';
    } else {
      endpoint = '$resourceType/upload';
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$endpoint'),
    );

    // Add standard fields
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = customFolder ?? folder;
    request.fields['resource_type'] = resourceType;

    // Add public_id if provided
    if (customPublicId != null) {
      request.fields['public_id'] = customPublicId;
    } else if (isAudio) {
      request.fields['public_id'] =
          'audio_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Add transformation parameters
    if (transformationParams != null && transformationParams.isNotEmpty) {
      final transformation = transformationParams.entries
          .map((e) => '${e.key}_${e.value}')
          .join(',');
      request.fields['transformation'] = transformation;
    }

    // Add format for audio
    if (isAudio) {
      final extension = file.path.split('.').last;
      request.fields['format'] = extension;
    }

    // Add file to request
    final mimeType = _getMimeType(file.path);
    final fileStream = await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: mimeType != null ? MediaType.parse(mimeType) : null,
    );
    request.files.add(fileStream);

    // Send request with progress tracking
    final response = await request.send();

    // Track upload progress if possible
    if (onProgress != null && response.stream.isBroadcast == false) {
      await _trackProgress(response, onProgress);
    }

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      print('Cloudinary error (${resourceType}): $responseBody');
      throw Exception('Upload failed with status: ${response.statusCode}');
    }

    if (onProgress != null) onProgress(1.0);

    final responseData = json.decode(responseBody);
    return responseData['secure_url'];
  }

  Future<void> _trackProgress(
      http.StreamedResponse response, Function(double) onProgress) async {
    // This is a simplified progress tracking
    // For real progress, you'd need to implement byte-by-byte tracking
    onProgress(0.3);
    await Future.delayed(const Duration(milliseconds: 100));
    onProgress(0.6);
    await Future.delayed(const Duration(milliseconds: 100));
    onProgress(0.9);
  }

  String? _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();

    switch (extension) {
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

  // Helper method to generate a random string for public_id if needed
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Get file size in MB
  static Future<double> getFileSizeInMB(File file) async {
    final size = await file.length();
    return size / (1024 * 1024);
  }

  /// Check if file format is supported
  static bool isFormatSupported(String filePath, String type) {
    final extension = filePath.split('.').last.toLowerCase();
    final supported = supportedFormats[type];
    return supported?.contains(extension) ?? false;
  }

  /// Get file type from path
  static String getFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    for (final entry in supportedFormats.entries) {
      if (entry.value.contains(extension)) {
        return entry.key;
      }
    }

    return 'unknown';
  }

  /// Generate a Cloudinary URL with transformations
  static String generateTransformedUrl(
      String originalUrl, Map<String, String> transformations) {
    // Parse the original URL
    // Example: https://res.cloudinary.com/cloudName/image/upload/v1234567890/folder/image.jpg
    final uri = Uri.parse(originalUrl);
    final pathParts = uri.path.split('/');

    // Find the upload index
    final uploadIndex = pathParts.indexWhere((part) => part == 'upload');
    if (uploadIndex == -1) return originalUrl;

    // Build transformation string
    final transformation =
        transformations.entries.map((e) => '${e.key}_${e.value}').join(',');

    // Insert transformation after 'upload'
    pathParts.insert(uploadIndex + 1, transformation);

    final newPath = pathParts.join('/');
    return uri.replace(path: newPath).toString();
  }
}

// Extension for easier usage
extension CloudinaryExtensions on CloudinaryService {
  Future<String> uploadWithAutoType(
    File file, {
    String? customFolder,
    Function(double)? onProgress,
  }) async {
    final type = CloudinaryService.getFileType(file.path);

    switch (type) {
      case 'image':
        return uploadImage(file,
            customFolder: customFolder, onProgress: onProgress);
      case 'video':
        return uploadVideo(file,
            customFolder: customFolder, onProgress: onProgress);
      case 'audio':
        return uploadAudio(file,
            customFolder: customFolder, onProgress: onProgress);
      case 'document':
        return uploadDocument(file, file.path.split('/').last,
            customFolder: customFolder, onProgress: onProgress);
      default:
        throw Exception('Unsupported file type: ${file.path}');
    }
  }
}
