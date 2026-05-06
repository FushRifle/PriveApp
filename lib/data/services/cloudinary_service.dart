import 'package:image_picker/image_picker.dart';
import 'upload_service.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  final UploadService _uploadService = UploadService();

  CloudinaryService._internal();

  // Upload image using signature-based auth
  Future<CloudinaryResponseModel?> uploadImage({
    required XFile file,
    String? folder,
    List<String>? tags,
    Function(double)? onProgress,
  }) async {
    return _uploadService.uploadImage(
      image: file,
      folder: folder,
      tags: tags,
      onProgress: onProgress,
    );
  }

  // Upload video using signature-based auth
  Future<CloudinaryResponseModel?> uploadVideo({
    required XFile file,
    String? folder,
    List<String>? tags,
    Function(double)? onProgress,
  }) async {
    return _uploadService.uploadVideo(
      video: file,
      folder: folder,
      tags: tags,
      onProgress: onProgress,
    );
  }

  // Delete file
  Future<bool> deleteFile(String publicId) async {
    return _uploadService.deleteFile(publicId);
  }

  // Get thumbnail URL
  String getThumbnailUrl(String publicId, {bool isVideo = false}) {
    return _uploadService.getThumbnailUrl(publicId, isVideo: isVideo);
  }

  // Get optimized URL
  String getOptimizedUrl(String publicId,
      {int? width, int? height, bool isVideo = false}) {
    return _uploadService.getOptimizedUrl(publicId,
        width: width, height: height, isVideo: isVideo);
  }

  // Get avatar URL
  String getAvatarUrl(String publicId) {
    return _uploadService.getAvatarUrl(publicId);
  }

  // Upload multiple images
  Future<List<CloudinaryResponseModel>> uploadMultipleImages({
    required List<XFile> files,
    String? folder,
    Function(int completed, int total)? onProgress,
  }) async {
    return _uploadService.uploadMultipleFiles(
      files: files,
      folder: folder ?? 'images',
      tags: ['prive', 'image'],
      resourceType: 'image',
      onProgress: onProgress,
    );
  }

  // Get responsive URL
  String getResponsiveUrl(String publicId, {required int width, int? height}) {
    return _uploadService.getResponsiveUrl(publicId,
        width: width, height: height);
  }
}
