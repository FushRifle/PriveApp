import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:social_media_app/app/configs/api_config.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  late final CloudinaryPublic _cloudinary;
  late final Cloudinary _cloudinarySigned;

  CloudinaryService._internal() {
    // Public upload (unsigned)
    _cloudinary = CloudinaryPublic(
      ApiConfig.cloudinaryCloudName,
      ApiConfig.cloudinaryUploadPreset,
      cache: false,
    );

    // Signed upload (server-side operations)
    _cloudinarySigned = Cloudinary(
      ApiConfig.cloudinaryCloudName,
      ApiConfig.cloudinaryApiKey,
      ApiConfig.cloudinaryApiSecret,
    );
  }

  // Upload image
  Future<CloudinaryResponse?> uploadImage({
    required XFile file,
    String? folder,
    Map<String, String>? tags,
    Map<String, String>? context,
  }) async {
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        file.path,
        identifier: file.name,
        folder: folder ?? 'prive_images',
        resourceType: CloudinaryResourceType.image,
        tags: tags ?? ['prive', 'image'],
        context: context,
      );

      final response = await _cloudinary.uploadFile(cloudinaryFile);

      if (response.isSuccessful) {
        return CloudinaryResponse(
          url: response.secureUrl,
          publicId: response.publicId,
          width: response.width,
          height: response.height,
          format: response.format,
          resourceType: response.resourceType,
          size: response.bytes,
          thumbnailUrl: _getTransformedUrl(
            response.publicId,
            width: 200,
            height: 200,
            crop: 'thumb',
          ),
        );
      }
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  // Upload video
  Future<CloudinaryResponse?> uploadVideo({
    required XFile file,
    String? folder,
    Map<String, String>? tags,
  }) async {
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        file.path,
        identifier: file.name,
        folder: folder ?? 'prive_videos',
        resourceType: CloudinaryResourceType.video,
        tags: tags ?? ['prive', 'video'],
      );

      final response = await _cloudinary.uploadFile(cloudinaryFile);

      if (response.isSuccessful) {
        return CloudinaryResponse(
          url: response.secureUrl,
          publicId: response.publicId,
          width: response.width,
          height: response.height,
          format: response.format,
          resourceType: response.resourceType,
          size: response.bytes,
          duration: response.duration,
          thumbnailUrl: _getTransformedUrl(
            response.publicId,
            width: 400,
            height: 400,
            crop: 'fill',
            resourceType: 'video',
          ),
        );
      }
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  // Upload multiple images
  Future<List<CloudinaryResponse>> uploadMultipleImages({
    required List<XFile> files,
    String? folder,
  }) async {
    final List<CloudinaryResponse> results = [];

    for (final file in files) {
      final response = await uploadImage(file: file, folder: folder);
      if (response != null) {
        results.add(response);
      }
    }

    return results;
  }

  // Get transformed URL
  String _getTransformedUrl(
    String publicId, {
    int? width,
    int? height,
    String? crop,
    String? gravity,
    String? resourceType,
    String? effect,
    int? quality,
  }) {
    final cloudinary = Cloudinary(
      ApiConfig.cloudinaryCloudName,
      ApiConfig.cloudinaryApiKey,
      ApiConfig.cloudinaryApiSecret,
    );

    final transformation = Transformation()
      ..width(width)
      ..height(height)
      ..crop(crop)
      ..gravity(gravity)
      ..effect(effect)
      ..quality(quality ?? 'auto');

    return cloudinary.image(publicId, transformation: transformation);
  }

  // Get thumbnail URL
  String getThumbnailUrl(String publicId, {int size = 200}) {
    return _getTransformedUrl(
      publicId,
      width: size,
      height: size,
      crop: 'thumb',
      gravity: 'face',
    );
  }

  // Get optimized URL
  String getOptimizedUrl(String publicId, {int? width, int? height}) {
    return _getTransformedUrl(
      publicId,
      width: width,
      height: height,
      crop: 'fill',
      quality: 80,
    );
  }

  // Get blur hash placeholder
  String getBlurredUrl(String publicId, {int blurIntensity = 1000}) {
    return _getTransformedUrl(
      publicId,
      width: 50,
      effect: 'blur:$blurIntensity',
      quality: 10,
    );
  }

  // Get avatar URL
  String getAvatarUrl(String publicId, {int size = 150}) {
    return _getTransformedUrl(
      publicId,
      width: size,
      height: size,
      crop: 'thumb',
      gravity: 'face',
      quality: 90,
    );
  }

  // Delete file
  Future<bool> deleteFile(String publicId,
      {String resourceType = 'image'}) async {
    try {
      final result = await _cloudinarySigned.destroy(
        publicId,
        resourceType: resourceType == 'video'
            ? CloudinaryResourceType.video
            : CloudinaryResourceType.image,
      );
      return result.isSuccessful;
    } catch (e) {
      print('Cloudinary delete error: $e');
      return false;
    }
  }

  // Rename file
  Future<bool> renameFile(String oldPublicId, String newPublicId) async {
    try {
      final result = await _cloudinarySigned.rename(oldPublicId, newPublicId);
      return result.isSuccessful;
    } catch (e) {
      print('Cloudinary rename error: $e');
      return false;
    }
  }

  // Check if file exists
  Future<bool> fileExists(String publicId) async {
    try {
      final result = await _cloudinarySigned.explicit(publicId);
      return result.isSuccessful;
    } catch (e) {
      return false;
    }
  }

  // Get resource info
  Future<CloudinaryResource?> getResourceInfo(String publicId) async {
    try {
      final result = await _cloudinarySigned.resource(publicId);
      if (result.isSuccessful) {
        return CloudinaryResource(
          publicId: result.publicId ?? '',
          url: result.secureUrl ?? '',
          width: result.width ?? 0,
          height: result.height ?? 0,
          format: result.format ?? '',
          size: result.bytes ?? 0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class CloudinaryResponse {
  final String url;
  final String publicId;
  final int? width;
  final int? height;
  final String? format;
  final String? resourceType;
  final int? size;
  final double? duration;
  final String? thumbnailUrl;

  CloudinaryResponse({
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

  Map<String, dynamic> toJson() {
    return {
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
}

class CloudinaryResource {
  final String publicId;
  final String url;
  final int width;
  final int height;
  final String format;
  final int size;

  CloudinaryResource({
    required this.publicId,
    required this.url,
    required this.width,
    required this.height,
    required this.format,
    required this.size,
  });
}
