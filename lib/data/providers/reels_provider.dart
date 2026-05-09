import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:Prive/data/models/reel_model.dart';
import 'package:Prive/data/services/reel/reel_service.dart';
import 'dart:async';

// Provider instances
final reelServiceProvider = Provider<ReelService>((ref) {
  return ReelService();
});

final reelsProvider = StateNotifierProvider<ReelsNotifier, ReelsState>((ref) {
  return ReelsNotifier(ref.read(reelServiceProvider));
});

// State class
class ReelsState {
  final List<ReelModel> reels;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final Map<String, bool> reelLikes;
  final Map<String, bool> reelShares;

  const ReelsState({
    this.reels = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
    this.reelLikes = const {},
    this.reelShares = const {},
  });

  ReelsState copyWith({
    List<ReelModel>? reels,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    Map<String, bool>? reelLikes,
    Map<String, bool>? reelShares,
  }) {
    return ReelsState(
      reels: reels ?? this.reels,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      reelLikes: reelLikes ?? this.reelLikes,
      reelShares: reelShares ?? this.reelShares,
    );
  }

  bool get isEmpty => reels.isEmpty && !isLoading && error == null;
  int get totalReels => reels.length;
  ReelModel? getReelById(String id) {
    try {
      return reels.firstWhere((reel) => reel.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Notifier
class ReelsNotifier extends StateNotifier<ReelsState> {
  final ReelService _reelService;
  Timer? _debounceTimer;

  ReelsNotifier(this._reelService) : super(const ReelsState());

  // Initial load
  Future<void> loadReels({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMore: true,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final page = refresh ? 1 : state.currentPage;
      final response = await _reelService.getReels(page: page);

      final List<ReelModel> newReels = response
          .map((data) => ReelModel.fromJson(data as Map<String, dynamic>))
          .toList();

      final hasMore = newReels.isNotEmpty;

      state = state.copyWith(
        reels: refresh ? newReels : [...state.reels, ...newReels],
        isLoading: false,
        hasMore: hasMore,
        currentPage: refresh ? 2 : state.currentPage + 1,
        error: null,
      );

      // Initialize like states
      final likeStates = <String, bool>{};
      for (final reel in newReels) {
        likeStates[reel.id] = reel.isLiked;
      }
      state = state.copyWith(reelLikes: {...state.reelLikes, ...likeStates});
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load more reels (pagination)
  Future<void> loadMoreReels() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _reelService.getReels(page: state.currentPage);

      final List<ReelModel> newReels = response
          .map((data) => ReelModel.fromJson(data as Map<String, dynamic>))
          .toList();

      final hasMore = newReels.isNotEmpty;

      state = state.copyWith(
        reels: [...state.reels, ...newReels],
        isLoadingMore: false,
        hasMore: hasMore,
        currentPage: state.currentPage + 1,
      );

      // Initialize like states for new reels
      final likeStates = <String, bool>{};
      for (final reel in newReels) {
        likeStates[reel.id] = reel.isLiked;
      }
      state = state.copyWith(reelLikes: {...state.reelLikes, ...likeStates});
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // Refresh reels
  Future<void> refreshReels() async {
    await loadReels(refresh: true);
  }

  // Like/Unlike reel
  Future<void> toggleLike(String reelId, int index) async {
    final isCurrentlyLiked = state.reelLikes[reelId] ?? false;
    final currentLikeCount = state.reels[index].likeCount;

    // Optimistic update
    state = state.copyWith(
      reelLikes: {...state.reelLikes, reelId: !isCurrentlyLiked},
      reels: [
        for (int i = 0; i < state.reels.length; i++)
          if (i == index)
            state.reels[i].copyWith(
              likeCount: currentLikeCount + (isCurrentlyLiked ? -1 : 1),
              isLiked: !isCurrentlyLiked,
            )
          else
            state.reels[i],
      ],
    );

    try {
      if (isCurrentlyLiked) {
        await _reelService.unlikeReel(reelId);
      } else {
        await _reelService.likeReel(reelId);
      }
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        reelLikes: {...state.reelLikes, reelId: isCurrentlyLiked},
        reels: [
          for (int i = 0; i < state.reels.length; i++)
            if (i == index)
              state.reels[i].copyWith(
                likeCount: currentLikeCount,
                isLiked: isCurrentlyLiked,
              )
            else
              state.reels[i],
        ],
      );
    }
  }

  // Share reel
  Future<void> shareReel(String reelId, int index) async {
    final currentShareCount = state.reels[index].shareCount;

    // Optimistic update
    state = state.copyWith(
      reelShares: {...state.reelShares, reelId: true},
      reels: [
        for (int i = 0; i < state.reels.length; i++)
          if (i == index)
            state.reels[i].copyWith(shareCount: currentShareCount + 1)
          else
            state.reels[i],
      ],
    );

    try {
      await _reelService.shareReel(reelId);
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        reelShares: {...state.reelShares, reelId: false},
        reels: [
          for (int i = 0; i < state.reels.length; i++)
            if (i == index)
              state.reels[i].copyWith(shareCount: currentShareCount)
            else
              state.reels[i],
        ],
      );
    }
  }

  // Add comment to reel
  Future<bool> addComment(String reelId, String comment, int index) async {
    try {
      final response = await _reelService.addReelComment(
        reelId: reelId,
        data: {'content': comment},
      );

      // Update comment count
      final currentCommentCount = state.reels[index].commentCount;
      state = state.copyWith(
        reels: [
          for (int i = 0; i < state.reels.length; i++)
            if (i == index)
              state.reels[i].copyWith(commentCount: currentCommentCount + 1)
            else
              state.reels[i],
        ],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get comments for a specific reel
  Future<List<dynamic>> getComments(String reelId, {int page = 1}) async {
    try {
      return await _reelService.getReelComments(reelId, page: page);
    } catch (e) {
      return [];
    }
  }

  // Create new reel
  Future<bool> createReel(Map<String, dynamic> reelData) async {
    try {
      final response = await _reelService.createReel(reelData);
      final newReel = ReelModel.fromJson(response);

      state = state.copyWith(reels: [newReel, ...state.reels]);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete reel (optimistic update)
  Future<bool> deleteReel(String reelId, int index) async {
    final reelToDelete = state.reels[index];

    // Optimistic update
    state = state.copyWith(
      reels: [
        for (int i = 0; i < state.reels.length; i++)
          if (i != index) state.reels[i],
      ],
    );

    try {
      // Implement delete API call if available
      // await _reelService.deleteReel(reelId);
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        reels: [
          ...state.reels.sublist(0, index),
          reelToDelete,
          ...state.reels.sublist(index),
        ],
      );
      return false;
    }
  }

  // Reset state
  void reset() {
    state = const ReelsState();
    _debounceTimer?.cancel();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Selectors for better performance
final reelsListProvider = Provider<List<ReelModel>>((ref) {
  return ref.watch(reelsProvider).reels;
});

final reelsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(reelsProvider).isLoading;
});

final reelsHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(reelsProvider).hasMore;
});

final reelsErrorProvider = Provider<String?>((ref) {
  return ref.watch(reelsProvider).error;
});

final reelsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(reelsProvider).isEmpty;
});

// Provider to get a specific reel by ID
final reelByIdProvider = Provider.family<ReelModel?, String>((ref, id) {
  return ref.watch(reelsProvider).getReelById(id);
});

// Provider to check if a reel is liked
final reelIsLikedProvider = Provider.family<bool, String>((ref, reelId) {
  return ref.watch(reelsProvider).reelLikes[reelId] ?? false;
});
