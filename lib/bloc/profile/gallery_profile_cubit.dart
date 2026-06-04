import 'package:clique/data/services/home/feed_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/data/models/gallery_model.dart';
part 'gallery_profile_state.dart';

class GalleryProfileCubit extends Cubit<GalleryProfileState> {
  final FeedService _feedService = FeedService();

  GalleryProfileCubit() : super(GalleryProfileInitial());

  // New method: Fetch media directly from API using FeedService
  Future<void> getUserMedia({
    required int userId,
    String? type, // 'image', 'video', or null for all
    int page = 1,
    bool loadMore = false,
  }) async {
    List<GalleryModel> previousItems = const [];

    if (loadMore && state is GalleryProfileLoaded) {
      final currentState = state as GalleryProfileLoaded;
      if (!currentState.hasMore) {
        return; // No more media to load
      }
      previousItems = currentState.galleryProfiles;
      emit(GalleryProfileLoadingMore(previousItems));
    } else {
      emit(GalleryProfileLoading());
    }

    try {
      final response = await _feedService.getUserMedia(
        userId: userId,
        page: page,
        type: type,
      );

      final mediaList = response.media;

      // Convert UserMedia to GalleryModel
      final galleryItems = mediaList
          .map((media) => GalleryModel(
                id: media.id.toString(),
                postId: media.postId,
                image: media.thumbnail ?? media.url,
                thumbnail: media.thumbnail ?? media.url,
                videoUrl: media.type == 'video' ? media.url : null,
                type: media.type,
                like: _formatLikes(media.likes),
                likesCount: media.likes,
                commentsCount: media.comments,
                caption: media.caption,
                createdAt: media.createdAt,
                createdAtDate: media.createdAt,
              ))
          .toList();

      if (loadMore) {
        final existingIds = previousItems.map((item) => item.id).toSet();
        final newItems = galleryItems
            .where((item) => !existingIds.contains(item.id))
            .toList();
        final allItems = [...previousItems, ...newItems];

        emit(GalleryProfileLoaded(
          galleryProfiles: allItems,
          hasMore: response.hasMore,
          currentPage: response.page,
        ));
      } else {
        emit(GalleryProfileLoaded(
          galleryProfiles: galleryItems,
          hasMore: response.hasMore,
          currentPage: response.page,
        ));
      }
    } catch (e) {
      emit(GalleryProfileError(message: e.toString()));
    }
  }

  // Load more media (pagination)
  Future<void> loadMoreMedia({
    required int userId,
    String? type,
  }) async {
    if (state is GalleryProfileLoaded) {
      final currentState = state as GalleryProfileLoaded;
      if (currentState.hasMore && !currentState.isLoadingMore) {
        final nextPage = (currentState.currentPage ?? 1) + 1;
        await getUserMedia(
          userId: userId,
          type: type,
          page: nextPage,
          loadMore: true,
        );
      }
    }
  }

  // Legacy method: Extract from feed posts (for backward compatibility)
  void getGalleryProfile({required List<dynamic> feedPosts}) {
    emit(GalleryProfileLoading());

    try {
      final galleryItems = _extractMediaFromPosts(feedPosts);
      emit(GalleryProfileLoaded(
        galleryProfiles: galleryItems,
        hasMore: false, // No pagination for local extraction
        currentPage: 1,
      ));
    } catch (e) {
      emit(GalleryProfileError(message: e.toString()));
    }
  }

  List<GalleryModel> _extractMediaFromPosts(List<dynamic> posts) {
    final List<GalleryModel> galleryItems = [];

    for (var post in posts) {
      // Extract post ID
      final postId = post['id']?.toString();
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
      final caption = post['content'] ?? post['caption'] ?? '';
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

  // Refresh gallery with new posts (legacy)
  void refreshGallery({required List<dynamic> feedPosts}) {
    getGalleryProfile(feedPosts: feedPosts);
  }

  // Clear gallery
  void clearGallery() {
    emit(GalleryProfileInitial());
  }
}
