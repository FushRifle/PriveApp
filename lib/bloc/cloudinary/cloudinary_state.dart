part of 'cloudinary_cubit.dart';

class CloudinaryState extends Equatable {
  final UploadStatus status;
  final UploadType? uploadType;
  final String? uploadedUrl;
  final File? uploadedFile;
  final double progress;
  final String? errorMessage;

  const CloudinaryState({
    this.status = UploadStatus.idle,
    this.uploadType,
    this.uploadedUrl,
    this.uploadedFile,
    this.progress = 0.0,
    this.errorMessage,
  });

  CloudinaryState copyWith({
    UploadStatus? status,
    UploadType? uploadType,
    String? uploadedUrl,
    File? uploadedFile,
    double? progress,
    String? errorMessage,
    bool clearUploadedUrl = false,
    bool clearUploadedFile = false,
    bool clearErrorMessage = false,
  }) {
    return CloudinaryState(
      status: status ?? this.status,
      uploadType: uploadType ?? this.uploadType,
      uploadedUrl: clearUploadedUrl ? null : uploadedUrl ?? this.uploadedUrl,
      uploadedFile:
          clearUploadedFile ? null : uploadedFile ?? this.uploadedFile,
      progress: progress ?? this.progress,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, uploadType, uploadedUrl, uploadedFile, progress, errorMessage];
}
