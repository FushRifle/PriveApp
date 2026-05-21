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
  }) {
    return CloudinaryState(
      status: status ?? this.status,
      uploadType: uploadType ?? this.uploadType,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      uploadedFile: uploadedFile ?? this.uploadedFile,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, uploadType, uploadedUrl, uploadedFile, progress, errorMessage];
}
