import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart' as cropper;
import 'package:image_picker/image_picker.dart';

class CropAspectRatio {
  final double ratioX;
  final double ratioY;

  const CropAspectRatio({
    required this.ratioX,
    required this.ratioY,
  });

  double get value => ratioX / ratioY;
}

class MediaService {
  final ImagePicker _picker = ImagePicker();

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
    BuildContext? context,
    CropAspectRatio? aspectRatio,
  }) async {
    try {
      final croppedFile = await cropper.ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: aspectRatio == null
            ? null
            : cropper.CropAspectRatio(
                ratioX: aspectRatio.ratioX,
                ratioY: aspectRatio.ratioY,
              ),
        uiSettings: [
          cropper.AndroidUiSettings(
            toolbarTitle: 'Crop photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: aspectRatio != null,
          ),
          cropper.IOSUiSettings(
            title: 'Crop photo',
            aspectRatioLockEnabled: aspectRatio != null,
          ),
          if (context != null)
            cropper.WebUiSettings(
              context: context,
            ),
        ],
      );

      if (croppedFile == null) return file;
      return XFile(croppedFile.path, name: file.name, mimeType: file.mimeType);
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return file;
    }
  }

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

  Future<double> getFileSize(XFile file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  Future<bool> isValidSize(XFile file, {double maxSizeMB = 10}) async {
    final size = await getFileSize(file);
    return size <= maxSizeMB;
  }
}
