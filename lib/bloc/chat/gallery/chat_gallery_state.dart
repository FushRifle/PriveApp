part of 'chat_gallery_cubit.dart';

abstract class ChatGalleryState extends Equatable {
  const ChatGalleryState();

  @override
  List<Object?> get props => [];
}

class ChatGalleryInitial extends ChatGalleryState {}

class ChatGalleryLoading extends ChatGalleryState {}

class ChatGalleryLoaded extends ChatGalleryState {
  final List<SharedMedia> images;
  final List<SharedMedia> videos;
  final List<SharedDocument> documents;

  const ChatGalleryLoaded({
    required this.images,
    required this.videos,
    required this.documents,
  });

  @override
  List<Object?> get props => [images, videos, documents];
}

class ChatGalleryError extends ChatGalleryState {
  final String message;

  const ChatGalleryError(this.message);

  @override
  List<Object?> get props => [message];
}
