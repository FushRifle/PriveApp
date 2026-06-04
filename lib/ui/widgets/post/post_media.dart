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
    final imageAttachments = post.attachments
        .where((attachment) => attachment.type.toLowerCase() == 'image')
        .take(4)
        .toList();
    final attachment = _primaryAttachment(post.attachments);

    if (attachment == null) {
      return const SizedBox.shrink();
    }

    final type = attachment.type.toLowerCase();
    final double aspectRatio = isDetailView ? 0.92 : 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: imageAttachments.length > 1
              ? _ImageCollage(
                  post: post,
                  attachments: imageAttachments,
                )
              : switch (type) {
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

class _ImageCollage extends StatelessWidget {
  final FeedPost post;
  final List<Attachment> attachments;

  const _ImageCollage({
    required this.post,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.length == 2) {
      return Row(
        children: [
          Expanded(child: _tile(attachments[0])),
          const SizedBox(width: 2),
          Expanded(child: _tile(attachments[1])),
        ],
      );
    }

    if (attachments.length == 3) {
      return Row(
        children: [
          Expanded(
            flex: 6,
            child: _tile(attachments[0]),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(child: _tile(attachments[1])),
                const SizedBox(height: 2),
                Expanded(child: _tile(attachments[2])),
              ],
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attachments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        return _tile(attachments[index]);
      },
    );
  }

  Widget _tile(Attachment attachment) {
    return PostImage(
      post: post,
      attachment: attachment,
    );
  }
}
