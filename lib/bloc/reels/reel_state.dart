part of 'reel_bloc.dart';

class ReelState extends Equatable {
  final List<dynamic> reels;
  final int currentPage;
  final bool hasMore;
  final ReelStatus status;
  final String? error;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final Set<int> likedReelIndices;
  final Set<String> sharingReelIds;

  const ReelState({
    this.reels = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.status = ReelStatus.initial,
    this.error,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.likedReelIndices = const {},
    this.sharingReelIds = const {},
  });

  ReelState copyWith({
    List<dynamic>? reels,
    int? currentPage,
    bool? hasMore,
    ReelStatus? status,
    String? error,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    Set<int>? likedReelIndices,
    Set<String>? sharingReelIds,
  }) {
    return ReelState(
      reels: reels ?? this.reels,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      status: status ?? this.status,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      likedReelIndices: likedReelIndices ?? this.likedReelIndices,
      sharingReelIds: sharingReelIds ?? this.sharingReelIds,
    );
  }

  @override
  List<Object?> get props => [
        reels,
        currentPage,
        hasMore,
        status,
        error,
        isLoading,
        isLoadingMore,
        isRefreshing,
        likedReelIndices,
        sharingReelIds,
      ];
}

enum ReelStatus {
  initial,
  loading,
  loadingMore,
  refreshing,
  success,
  error,
}
