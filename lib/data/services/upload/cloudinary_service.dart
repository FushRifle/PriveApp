import 'package:image_picker/image_picker.dart';
import 'upload_service.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  final UploadService _uploadService = UploadService();

  CloudinaryService._internal();

  // Upload image using UploadService
  Future<CloudinaryResponseModel?> uploadImage({
    required XFile file,
    String? folder,
    Function(double)? onProgress,
  }) async {
    return _uploadService.uploadImage(
      image: file,
      folder: folder,
      onProgress: onProgress,
    );
  }

  // Upload video using UploadService
  Future<CloudinaryResponseModel?> uploadVideo({
    required XFile file,
    String? folder,
    Function(double)? onProgress,
  }) async {
    return _uploadService.uploadVideo(
      video: file,
      folder: folder,
      onProgress: onProgress,
    );
  }

  // Delete file
  Future<bool> deleteFile(String publicId) async {
    return _uploadService.deleteFile(publicId);
  }
}
