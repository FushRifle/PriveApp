import 'package:clique/data/models/feeds_models.dart';
import 'package:clique/ui/widgets/post/post_document.dart';
import 'package:clique/ui/widgets/post/post_image.dart';
import 'package:clique/ui/widgets/post/post_video.dart';
import 'package:flutter/material.dart';

class PostMedia extends StatelessWidget {
  final FeedPost post;
  final bool isDetailView;

  const PostMedia({
    super.key,
    required this.post,
    this.isDetailView = false,
  });

  @override
  Widget build(BuildContext context) {
    final attachment = _primaryAttachment(post.attachments);

    if (attachment == null) {
      return const SizedBox.shrink();
    }

    final type = attachment.type.toLowerCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: isDetailView ? 0.92 : 1,
          child: switch (type) {
            'image' => PostImage(
                post: post,
                attachment: attachment,
              ),
            'video' => PostVideo(
                post: post,
                attachment: attachment,
              ),
            'document' || 'file' || 'pdf' => PostDocument(
                post: post,
                attachment: attachment,
              ),
            _ => PostDocument(
                post: post,
                attachment: attachment,
              ),
          },
        ),
      ),
    );
  }

  Attachment? _primaryAttachment(List<Attachment> attachments) {
    if (attachments.isEmpty) return null;

    for (final attachment in attachments) {
      final type = attachment.type.toLowerCase();

      if (type == 'image') return attachment;
    }

    for (final attachment in attachments) {
      final type = attachment.type.toLowerCase();

      if (type == 'video') return attachment;
    }

    return attachments.first;
  }
}
