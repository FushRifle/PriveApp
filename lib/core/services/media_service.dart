import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  // Pick single image
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 85,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Pick multiple images
  Future<List<XFile>> pickMultipleImages({
    int? imageQuality,
    double? maxWidth,
  }) async {
    try {
      return await _picker.pickMultiImage(
        imageQuality: imageQuality ?? 85,
        maxWidth: maxWidth,
      );
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  // Pick video
  Future<XFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      return await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  // Get file size in MB
  Future<double> getFileSize(XFile file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024); // Convert to MB
  }

  // Validate file size
  Future<bool> isValidSize(XFile file, {double maxSizeMB = 10}) async {
    final size = await getFileSize(file);
    return size <= maxSizeMB;
  }
}
