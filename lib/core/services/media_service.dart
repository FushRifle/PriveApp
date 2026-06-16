import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clique/app/configs/colors.dart';

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

  Future<XFile?> cropImage(
    XFile file, {
    CropAspectRatio? aspectRatio,
  }) async {
    try {
      final window = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
          ? WidgetsBinding.instance.platformDispatcher.views.first
          : null;
      final logicalSize = window == null
          ? const Size(0, 0)
          : window.physicalSize / window.devicePixelRatio;
      final isCompactCropper =
          logicalSize.width < 390 || logicalSize.height < 720;

      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressQuality: 92,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isCompactCropper ? 'Crop' : 'Crop photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            statusBarColor: Colors.black,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppColors.primary,
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white24,
            showCropGrid: true,
            hideBottomControls: isCompactCropper,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: aspectRatio != null,
          ),
          IOSUiSettings(
            title: isCompactCropper ? 'Crop' : 'Crop photo',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: aspectRatio != null,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (cropped == null) return file;
      return XFile(cropped.path, name: file.name, mimeType: file.mimeType);
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return file;
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
