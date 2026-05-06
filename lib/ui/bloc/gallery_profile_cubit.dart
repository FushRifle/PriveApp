// gallery_profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/data/models/gallery_model.dart';

part 'gallery_profile_state.dart';

class GalleryProfileCubit extends Cubit<GalleryProfileState> {
  GalleryProfileCubit() : super(GalleryProfileInitial());

  void getGalleryProfile({required List<dynamic> feedPosts}) {
    emit(GalleryProfileLoading());

    try {
      // Filter attachments from user feeds
      final galleryItems = _extractMediaFromPosts(feedPosts);

      emit(GalleryProfileLoaded(galleryProfiles: galleryItems));
    } catch (e) {
      emit(GalleryProfileError(message: e.toString()));
    }
  }

  List<GalleryModel> _extractMediaFromPosts(List<dynamic> posts) {
    final List<GalleryModel> galleryItems = [];

    for (var post in posts) {
      // Extract post ID
      final postId = post['id']?.toString();

      // Extract likes count from various possible structures
      int likesCount = 0;
      if (post['likesCount'] != null) {
        likesCount = post['likesCount'];
      } else if (post['likes'] is List) {
        likesCount = post['likes'].length;
      } else if (post['_count'] != null && post['_count']['likes'] != null) {
        likesCount = post['_count']['likes'];
      } else if (post['likeCount'] != null) {
        likesCount = post['likeCount'];
      }

      // Extract content/caption
      final caption = post['content'] ?? post['caption'] ?? '';

      // Check for attachments array (most common structure)
      final attachments = post['attachments'] ?? [];

      if (attachments.isNotEmpty) {
        // Process each attachment
        for (var attachment in attachments) {
          final type = attachment['type']?.toString().toLowerCase();
          final url =
              attachment['url'] ?? attachment['uri'] ?? attachment['file'];

          if (url != null && url.toString().isNotEmpty) {
            if (type == 'image' ||
                (type == null &&
                    url
                        .toString()
                        .contains(RegExp(r'\.(jpg|jpeg|png|gif|webp)')))) {
              galleryItems.add(GalleryModel(
                id: postId,
                image: url.toString(),
                type: 'image',
                like: _formatLikes(likesCount),
                caption: caption,
                createdAt: post['createdAt'] ??
                    post['created_at'] ??
                    post['timestamp'],
              ));
            } else if (type == 'video' ||
                url.toString().contains(RegExp(r'\.(mp4|mov|avi|webm)'))) {
              galleryItems.add(GalleryModel(
                id: postId,
                image: attachment['thumbnail'] ??
                    attachment['thumb'] ??
                    url.toString(),
                videoUrl: url.toString(),
                type: 'video',
                like: _formatLikes(likesCount),
                caption: caption,
                createdAt: post['createdAt'] ??
                    post['created_at'] ??
                    post['timestamp'],
              ));
            }
          }
        }
      }

      // Check for single imageUrl field
      final imageUrl = post['imageUrl'] ?? post['image_url'] ?? post['image'];
      if (imageUrl != null &&
          imageUrl.toString().isNotEmpty &&
          attachments.isEmpty) {
        galleryItems.add(GalleryModel(
          id: postId,
          image: imageUrl.toString(),
          type: 'image',
          like: _formatLikes(likesCount),
          caption: caption,
          createdAt:
              post['createdAt'] ?? post['created_at'] ?? post['timestamp'],
        ));
      }

      // Check for single videoUrl field
      final videoUrl = post['videoUrl'] ?? post['video_url'] ?? post['video'];
      if (videoUrl != null &&
          videoUrl.toString().isNotEmpty &&
          attachments.isEmpty) {
        galleryItems.add(GalleryModel(
          id: postId,
          image:
              post['thumbnail'] ?? post['thumbnail_url'] ?? post['thumb'] ?? '',
          videoUrl: videoUrl.toString(),
          type: 'video',
          like: _formatLikes(likesCount),
          caption: caption,
          createdAt:
              post['createdAt'] ?? post['created_at'] ?? post['timestamp'],
        ));
      }
    }

    // Sort by date (newest first)
    galleryItems.sort((a, b) {
      final dateA = a.createdAt != null ? _parseDate(a.createdAt) : null;
      final dateB = b.createdAt != null ? _parseDate(b.createdAt) : null;
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      return 0;
    });

    return galleryItems;
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) return DateTime.tryParse(dateValue);
      if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String _formatLikes(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Refresh gallery with new posts
  void refreshGallery({required List<dynamic> feedPosts}) {
    getGalleryProfile(feedPosts: feedPosts);
  }

  // Clear gallery
  void clearGallery() {
    emit(GalleryProfileInitial());
  }
}
