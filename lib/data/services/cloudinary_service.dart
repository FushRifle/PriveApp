import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Prive/app/configs/api_config.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  late final CloudinaryPublic _cloudinary;

  CloudinaryService._internal() {
    _cloudinary = CloudinaryPublic(
      ApiConfig.cloudinaryCloudName,
      ApiConfig.cloudinaryUploadPreset,
      cache: false,
    );
  }

  // Upload image
  Future<CloudinaryResponseModel?> uploadImage({
    required XFile file,
    String? folder,
    List<String>? tags,
  }) async {
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        file.path,
        identifier: file.name,
        folder: folder ?? 'prive_images',
        resourceType: CloudinaryResourceType.Image,
        tags: tags ?? ['prive', 'image'],
      );

      final response = await _cloudinary.uploadFile(cloudinaryFile);

      if (response.secureUrl.isNotEmpty) {
        return CloudinaryResponseModel(
          url: response.secureUrl,
          publicId: response.publicId ?? '',
          thumbnailUrl: _getTransformedUrl(
            response.publicId ?? '',
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
  Future<CloudinaryResponseModel?> uploadVideo({
    required XFile file,
    String? folder,
    List<String>? tags,
  }) async {
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        file.path,
        identifier: file.name,
        folder: folder ?? 'prive_videos',
        resourceType: CloudinaryResourceType.Video,
        tags: tags ?? ['prive', 'video'],
      );

      final response = await _cloudinary.uploadFile(cloudinaryFile);

      if (response.secureUrl.isNotEmpty) {
        return CloudinaryResponseModel(
          url: response.secureUrl,
          publicId: response.publicId ?? '',
          thumbnailUrl: _getTransformedUrl(
            response.publicId ?? '',
            width: 400,
            height: 400,
            crop: 'fill',
          ),
        );
      }
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  // Get transformed URL from public ID
  String _getTransformedUrl(
    String publicId, {
    int? width,
    int? height,
    String? crop,
    String? gravity,
  }) {
    String url =
        'https://res.cloudinary.com/${ApiConfig.cloudinaryCloudName}/image/upload';

    List<String> transformations = [];

    if (crop != null) transformations.add('c_$crop');
    if (gravity != null) transformations.add('g_$gravity');
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_auto:eco');

    if (transformations.isNotEmpty) {
      url += '/${transformations.join(',')}';
    }

    return '$url/$publicId';
  }

  // Get thumbnail URL
  String getThumbnailUrl(String publicId) {
    return _getTransformedUrl(
      publicId,
      width: 200,
      height: 200,
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

  // Upload multiple images
  Future<List<CloudinaryResponseModel>> uploadMultipleImages({
    required List<XFile> files,
    String? folder,
  }) async {
    final List<CloudinaryResponseModel> results = [];
    for (final file in files) {
      final response = await uploadImage(file: file, folder: folder);
      if (response != null) results.add(response);
    }
    return results;
  }

  // Delete file
  Future<bool> deleteFile(String publicId) async {
    try {
      await _cloudinary.destroy(publicId);
      return true;
    } catch (e) {
      print('Cloudinary delete error: $e');
      return false;
    }
  }
}

extension on CloudinaryPublic {
  Future<void> destroy(String publicId) async {}
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
