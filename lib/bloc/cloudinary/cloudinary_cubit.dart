import 'package:bloc/bloc.dart';
import 'package:clique/core/cloudinary_service.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';

part 'cloudinary_state.dart';

enum UploadType { image, video, audio, document }

enum UploadStatus { idle, picking, uploading, success, error }

class CloudinaryCubit extends Cubit<CloudinaryState> {
  final CloudinaryService _cloudinaryService;

  CloudinaryCubit({CloudinaryService? cloudinaryService})
      : _cloudinaryService = cloudinaryService ?? CloudinaryService(),
        super(const CloudinaryState());

  // Generic upload method
  Future<void> uploadFile({
    required UploadType type,
    File? file,
    String? customFolder,
    bool pickFromGallery = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      File? selectedFile = file;

      // Pick file if not provided
      if (pickFromGallery && selectedFile == null) {
        emit(state.copyWith(
          status: UploadStatus.picking,
          uploadType: type,
          progress: 0.0,
        ));

        selectedFile = await _pickFile(type, allowedExtensions);

        if (selectedFile == null) {
          emit(state.copyWith(status: UploadStatus.idle));
          return;
        }
      }

      if (selectedFile == null) {
        emit(state.copyWith(
          status: UploadStatus.error,
          errorMessage: 'No file selected',
        ));
        return;
      }

      // Validate file
      final validationError = await _validateFile(selectedFile, type);
      if (validationError != null) {
        emit(state.copyWith(
          status: UploadStatus.error,
          errorMessage: validationError,
        ));
        return;
      }

      // Start upload
      emit(state.copyWith(
        status: UploadStatus.uploading,
        uploadType: type,
        progress: 0.0,
        errorMessage: null,
      ));

      String url;

      // Upload based on type
      switch (type) {
        case UploadType.image:
          url = await _cloudinaryService.uploadImage(
            selectedFile,
            customFolder: customFolder,
            onProgress: (progress) => _updateProgress(progress),
          );
          break;
        case UploadType.video:
          url = await _cloudinaryService.uploadVideo(
            selectedFile,
            customFolder: customFolder,
            onProgress: (progress) => _updateProgress(progress),
          );
          break;
        case UploadType.audio:
          url = await _cloudinaryService.uploadAudio(
            selectedFile,
            customFolder: customFolder,
            onProgress: (progress) => _updateProgress(progress),
          );
          break;
        case UploadType.document:
          url = await _cloudinaryService.uploadDocument(
            selectedFile,
            selectedFile.path.split('/').last,
          );
          _updateProgress(1.0);
          break;
      }

      emit(state.copyWith(
        status: UploadStatus.success,
        uploadedUrl: url,
        uploadedFile: selectedFile,
        progress: 1.0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Upload failed: ${e.toString()}',
      ));
    }
  }

  Future<File?> _pickFile(
      UploadType type, List<String>? allowedExtensions) async {
    // You can use image_picker, file_picker, etc.
    // This is a placeholder - implement based on your needs
    return null;
  }

  Future<String?> _validateFile(File file, UploadType type) async {
    final size = await file.length();
    final sizeInMB = size / (1024 * 1024);

    switch (type) {
      case UploadType.image:
        if (sizeInMB > 10) return 'Image size must be less than 10MB';
        break;
      case UploadType.video:
        if (sizeInMB > 100) return 'Video size must be less than 100MB';
        break;
      case UploadType.audio:
        if (sizeInMB > 25) return 'Audio size must be less than 25MB';
        break;
      case UploadType.document:
        if (sizeInMB > 15) return 'Document size must be less than 15MB';
        break;
    }

    return null;
  }

  void _updateProgress(double progress) {
    emit(state.copyWith(progress: progress));
  }

  void reset() {
    emit(const CloudinaryState());
  }

  void clearUrl() {
    emit(state.copyWith(uploadedUrl: null));
  }
}
