part of 'gallery_profile_cubit.dart';

abstract class GalleryProfileState extends Equatable {
  const GalleryProfileState();

  @override
  List<Object?> get props => [];
}

class GalleryProfileInitial extends GalleryProfileState {}

class GalleryProfileLoading extends GalleryProfileState {}

class GalleryProfileLoadingMore extends GalleryProfileState {
  final List<GalleryModel> currentProfiles;

  const GalleryProfileLoadingMore(this.currentProfiles);

  @override
  List<Object?> get props => [currentProfiles];
}

class GalleryProfileLoaded extends GalleryProfileState {
  final List<GalleryModel> galleryProfiles;
  final bool hasMore;
  final int? currentPage;
  final bool isLoadingMore;

  const GalleryProfileLoaded({
    required this.galleryProfiles,
    this.hasMore = false,
    this.currentPage,
    this.isLoadingMore = false,
  });

  GalleryProfileLoaded copyWith({
    List<GalleryModel>? galleryProfiles,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return GalleryProfileLoaded(
      galleryProfiles: galleryProfiles ?? this.galleryProfiles,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [galleryProfiles, hasMore, currentPage, isLoadingMore];
}

class GalleryProfileError extends GalleryProfileState {
  final String message;

  const GalleryProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
