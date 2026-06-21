import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:clique/ui/pages/common/crop_photo_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
    if (context == null) return file;

    try {
      final bytes = await file.readAsBytes();
      if (!context.mounted) return file;

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => CropPhotoPage(
            imageBytes: bytes,
            aspectRatio: aspectRatio?.value,
          ),
        ),
      );

      if (croppedBytes == null || croppedBytes.isEmpty) return file;

      final directory = await getTemporaryDirectory();
      final extension = _extensionFor(file.name);
      final path =
          '${directory.path}/cropped_${DateTime.now().microsecondsSinceEpoch}$extension';
      final output = File(path);
      await output.writeAsBytes(croppedBytes, flush: true);
      return XFile(output.path, name: file.name, mimeType: file.mimeType);
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

  String _extensionFor(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '.jpg';
    return name.substring(dot);
  }

}
