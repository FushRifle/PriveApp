part of 'reel_bloc.dart';

enum ReelStatus {
  initial,
  loading,
  refreshing,
  loadingMore,
  creating,
  created,
  success,
  error,
}

class ReelState extends Equatable {
  final ReelStatus status;
  final List<dynamic> reels;
  final int currentPage;
  final bool hasMore;
  final String? error;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isCreating;

  const ReelState({
    this.status = ReelStatus.initial,
    this.reels = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.error,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isCreating = false,
  });

  ReelState copyWith({
    ReelStatus? status,
    List<dynamic>? reels,
    int? currentPage,
    bool? hasMore,
    String? error,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isCreating,
    bool clearError = false,
  }) {
    return ReelState(
      status: status ?? this.status,
      reels: reels ?? this.reels,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
    );
  }

  @override
  List<Object?> get props => [
        status,
        reels,
        currentPage,
        hasMore,
        error,
        isLoading,
        isRefreshing,
        isLoadingMore,
        isCreating,
      ];
}
