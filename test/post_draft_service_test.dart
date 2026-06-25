import 'dart:io';

import 'package:clique/core/models/create_post_models.dart';
import 'package:clique/core/services/home/post_draft_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mediaItemsFromDraft restores existing local media only', () async {
    final tempDir = await Directory.systemTemp.createTemp('draft_media_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final image = File('${tempDir.path}/draft.jpg');
    await image.writeAsBytes([1, 2, 3]);

    final media = PostDraftService.mediaItemsFromDraft({
      'mediaItems': [
        {
          'path': image.path,
          'fileName': 'draft.jpg',
          'type': 'image',
        },
        {
          'path': '${tempDir.path}/missing.mp4',
          'fileName': 'missing.mp4',
          'type': 'video',
        },
      ],
    });

    expect(media, hasLength(1));
    expect(media.single.type, MediaType.image);
    expect(media.single.fileName, 'draft.jpg');
  });
}
