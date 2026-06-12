import 'dart:io';
import 'dart:typed_data';

enum PostComposerType {
  post,
  poll,
  question,
  anonymous;

  String get apiValue => switch (this) {
        PostComposerType.post => 'standard',
        PostComposerType.poll => 'poll',
        PostComposerType.question => 'question',
        PostComposerType.anonymous => 'anonymous',
      };

  String get label => switch (this) {
        PostComposerType.post => 'Post',
        PostComposerType.poll => 'Poll',
        PostComposerType.question => 'Question',
        PostComposerType.anonymous => 'Anonymous',
  };
}

enum PostCreationStep {
  options,
  textInput,
  mediaPreview,
}

enum MediaType {
  image,
  video,
}

class MediaItem {
  final File? file;
  final Uint8List? fileBytes;
  final String? fileName;
  final MediaType type;

  const MediaItem({
    this.file,
    this.fileBytes,
    this.fileName,
    required this.type,
  });
}
