import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Prive/app/configs/api_config.dart';
import 'package:Prive/data/services/api_service.dart';

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;

  final ApiService _apiService = ApiService();

  UploadService._internal();

  Future<SignatureResponse?> _getSignature({
    required String folder,
    List<String>? tags,
    String resourceType = 'image',
  }) async {
    try {
      final response = await _apiService.post(
        '/upload/sign',
        data: {
          'folder': folder,
          'tags': tags ?? [],
          'resourceType': resourceType,
        },
      );

      if (response.statusCode == 200) {
        return SignatureResponse.fromJson(response.data);
      } else {
        print('Failed to get signature: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Error getting signature: $e');
      return null;
    }
  }

  // Upload file to Cloudinary directly with signature
  Future<CloudinaryResponseModel?> uploadFile({
    required XFile file,
    required String folder,
    List<String>? tags,
    String resourceType = 'image',
    Function(double)? onProgress,
  }) async {
    try {
      // Get signature from backend
      final signature = await _getSignature(
        folder: folder,
        tags: tags,
        resourceType: resourceType,
      );

      if (signature == null) {
        throw Exception('Failed to get upload signature');
      }

      // Prepare multipart request to Cloudinary using Dio
      final uploadUrl =
          'https://api.cloudinary.com/v1_${signature.cloudName}/$resourceType/upload';

      // Create FormData for Dio
      final formData = dio.FormData.fromMap({
        'api_key': signature.apiKey,
        'timestamp': signature.timestamp.toString(),
        'signature': signature.signature,
        'upload_preset': signature.uploadPreset,
        'folder': signature.folder,
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.name,
          contentType: _getContentType(file.name, resourceType),
        ),
      });

      // Create a separate Dio instance for Cloudinary upload
      final cloudinaryDio = Dio();

      // Send request with progress tracking
      final response = await cloudinaryDio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            final progress = sent / total;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return CloudinaryResponseModel(
          url: data['secure_url'],
          publicId: data['public_id'],
          width: data['width'],
          height: data['height'],
          format: data['format'],
          resourceType: resourceType,
          size: data['bytes'],
          duration: data['duration'],
          thumbnailUrl: resourceType == 'video'
              ? _getVideoThumbnail(data['public_id'])
              : _getTransformedUrl(
                  data['public_id'],
                  width: 200,
                  height: 200,
                  crop: 'thumb',
                ),
        );
      } else {
        print('Upload failed: ${response.data}');
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
    List<String>? tags,
    Function(double)? onProgress,
  }) async {
    return uploadFile(
      file: image,
      folder: folder ?? 'images',
      tags: tags ?? ['prive', 'image'],
      resourceType: 'image',
      onProgress: onProgress,
    );
  }

  // Upload video
  Future<CloudinaryResponseModel?> uploadVideo({
    required XFile video,
    String? folder,
    List<String>? tags,
    Function(double)? onProgress,
  }) async {
    return uploadFile(
      file: video,
      folder: folder ?? 'videos',
      tags: tags ?? ['prive', 'video'],
      resourceType: 'video',
      onProgress: onProgress,
    );
  }

  // Upload multiple files
  Future<List<CloudinaryResponseModel>> uploadMultipleFiles({
    required List<XFile> files,
    required String folder,
    List<String>? tags,
    String resourceType = 'image',
    Function(int completed, int total)? onProgress,
  }) async {
    final List<CloudinaryResponseModel> results = [];
    int completed = 0;

    for (final file in files) {
      final response = await uploadFile(
        file: file,
        folder: folder,
        tags: tags,
        resourceType: resourceType,
      );

      if (response != null) {
        results.add(response);
      }

      completed++;
      if (onProgress != null) {
        onProgress(completed, files.length);
      }
    }

    return results;
  }

  // Delete file from Cloudinary using ApiService
  Future<bool> deleteFile(String publicId) async {
    try {
      final response = await _apiService.delete('/upload/$publicId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Helper to get content type
  MediaType _getContentType(String fileName, String resourceType) {
    final extension = fileName.split('.').last.toLowerCase();

    if (resourceType == 'video') {
      switch (extension) {
        case 'mp4':
          return MediaType('video', 'mp4');
        case 'mov':
          return MediaType('video', 'quicktime');
        case 'avi':
          return MediaType('video', 'x-msvideo');
        case 'mkv':
          return MediaType('video', 'x-matroska');
        default:
          return MediaType('video', 'mp4');
      }
    } else {
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          return MediaType('image', 'jpeg');
        case 'png':
          return MediaType('image', 'png');
        case 'gif':
          return MediaType('image', 'gif');
        case 'webp':
          return MediaType('image', 'webp');
        case 'heic':
          return MediaType('image', 'heic');
        default:
          return MediaType('image', 'jpeg');
      }
    }
  }

  // Get transformed URL from public ID
  String _getTransformedUrl(
    String publicId, {
    int? width,
    int? height,
    String? crop,
    String? gravity,
    String? quality = 'auto',
    String? format,
  }) {
    String url =
        'https://res.cloudinary.com/${ApiConfig.cloudinaryCloudName}/image/upload';

    List<String> transformations = [];

    if (crop != null) transformations.add('c_$crop');
    if (gravity != null) transformations.add('g_$gravity');
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (quality != null) transformations.add('q_$quality');
    if (format != null) transformations.add('f_$format');

    transformations.add('q_auto:eco');

    if (transformations.isNotEmpty) {
      url += '/${transformations.join(',')}';
    }

    return '$url/$publicId';
  }

  // Get video thumbnail
  String _getVideoThumbnail(String publicId, {int seconds = 1}) {
    return 'https://res.cloudinary.com/${ApiConfig.cloudinaryCloudName}/video/upload/so_$seconds/$publicId.jpg';
  }

  // Get thumbnail URL
  String getThumbnailUrl(String publicId, {bool isVideo = false}) {
    if (isVideo) {
      return _getVideoThumbnail(publicId);
    }
    return _getTransformedUrl(
      publicId,
      width: 200,
      height: 200,
      crop: 'thumb',
      gravity: 'face',
    );
  }

  // Get optimized URL
  String getOptimizedUrl(String publicId,
      {int? width, int? height, bool isVideo = false}) {
    if (isVideo) {
      return 'https://res.cloudinary.com/${ApiConfig.cloudinaryCloudName}/video/upload/w_${width ?? 'auto'},h_${height ?? 'auto'},c_limit,q_auto/$publicId';
    }
    return _getTransformedUrl(
      publicId,
      width: width,
      height: height,
      crop: 'fill',
    );
  }

  // Get avatar URL
  String getAvatarUrl(String publicId) {
    return _getTransformedUrl(
      publicId,
      width: 150,
      height: 150,
      crop: 'thumb',
      gravity: 'face',
    );
  }

  // Get responsive image URL for different screen sizes
  String getResponsiveUrl(String publicId, {required int width, int? height}) {
    return _getTransformedUrl(
      publicId,
      width: width,
      height: height,
      crop: 'limit',
    );
  }

  // Get image with specific transformations
  String getTransformedImageUrl(
      String publicId, Map<String, dynamic> transformations) {
    String url =
        'https://res.cloudinary.com/${ApiConfig.cloudinaryCloudName}/image/upload';

    final List<String> transforms = [];
    transformations.forEach((key, value) {
      transforms.add('${key[0]}_$value');
    });

    if (transforms.isNotEmpty) {
      url += '/${transforms.join(',')}';
    }

    return '$url/$publicId';
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

  Map<String, dynamic> toJson() => {
        'url': url,
        'publicId': publicId,
        'width': width,
        'height': height,
        'format': format,
        'resourceType': resourceType,
        'size': size,
        'duration': duration,
        'thumbnailUrl': thumbnailUrl,
      };
}
