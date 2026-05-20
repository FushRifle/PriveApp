import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/chat/chat_service.dart';

part 'chat_gallery_state.dart';

class ChatGalleryCubit extends Cubit<ChatGalleryState> {
  final ChatService _chatService = ChatService();

  ChatGalleryCubit() : super(ChatGalleryInitial());

  Future<void> loadSharedMedia(int conversationId) async {
    emit(ChatGalleryLoading());

    try {
      // Get messages from the conversation
      final messages = await _chatService.getMessages(conversationId, page: 1);

      final images = <SharedMedia>[];
      final videos = <SharedMedia>[];
      final documents = <SharedDocument>[];

      for (final msg in messages) {
        if (msg['messageType'] == 'image' && msg['mediaUrl'] != null) {
          images.add(SharedMedia(
            url: msg['mediaUrl'],
            createdAt: DateTime.parse(msg['createdAt']),
            senderId: msg['senderId'],
          ));
        } else if (msg['messageType'] == 'video' && msg['mediaUrl'] != null) {
          videos.add(SharedMedia(
            url: msg['mediaUrl'],
            createdAt: DateTime.parse(msg['createdAt']),
            senderId: msg['senderId'],
          ));
        } else if (msg['messageType'] == 'document' &&
            msg['mediaUrl'] != null) {
          documents.add(SharedDocument(
            url: msg['mediaUrl'],
            name: msg['message'] ?? 'Document',
            size: _getFileSize(msg['mediaUrl']),
            createdAt: DateTime.parse(msg['createdAt']),
            senderId: msg['senderId'],
          ));
        }
      }

      emit(ChatGalleryLoaded(
        images: images,
        videos: videos,
        documents: documents,
      ));
    } catch (e) {
      emit(ChatGalleryError(e.toString()));
    }
  }

  String _getFileSize(String url) {
    // This is a placeholder - in production, you'd get file size from metadata
    return 'Unknown size';
  }
}

class SharedMedia {
  final String url;
  final DateTime createdAt;
  final int senderId;

  SharedMedia({
    required this.url,
    required this.createdAt,
    required this.senderId,
  });
}

class SharedDocument {
  final String url;
  final String name;
  final String size;
  final DateTime createdAt;
  final int senderId;

  SharedDocument({
    required this.url,
    required this.name,
    required this.size,
    required this.createdAt,
    required this.senderId,
  });
}
