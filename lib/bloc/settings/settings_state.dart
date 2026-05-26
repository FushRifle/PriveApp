part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  // Settings values
  final bool? notificationsEnabled;
  final bool? privateAccount;
  final bool? twoFactorAuth;
  final String? language;
  final String? videoQuality;
  final String? theme;
  final bool? autoPlayVideos;
  final bool? saveOriginalPhotos;
  final bool? showActivityStatus;
  final bool? allowTagging;

  // Status
  final SettingsStatus status;
  final String? error;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final DateTime? lastUpdated;

  const SettingsState({
    this.notificationsEnabled,
    this.privateAccount,
    this.twoFactorAuth,
    this.language,
    this.videoQuality,
    this.theme,
    this.autoPlayVideos,
    this.saveOriginalPhotos,
    this.showActivityStatus,
    this.allowTagging,
    this.status = SettingsStatus.initial,
    this.error,
    this.isLoading = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.lastUpdated,
  });

  // Helper getters for common defaults
  bool get getNotificationsEnabled => notificationsEnabled ?? true;
  bool get getPrivateAccount => privateAccount ?? false;
  bool get getTwoFactorAuth => twoFactorAuth ?? false;
  String get getLanguage => language ?? 'en';
  String get getVideoQuality => videoQuality ?? 'auto';
  String get getTheme => theme ?? 'system';
  bool get getAutoPlayVideos => autoPlayVideos ?? true;
  bool get getSaveOriginalPhotos => saveOriginalPhotos ?? false;
  bool get getShowActivityStatus => showActivityStatus ?? true;
  bool get getAllowTagging => allowTagging ?? true;

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? privateAccount,
    bool? twoFactorAuth,
    String? language,
    String? videoQuality,
    String? theme,
    bool? autoPlayVideos,
    bool? saveOriginalPhotos,
    bool? showActivityStatus,
    bool? allowTagging,
    SettingsStatus? status,
    String? error,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      privateAccount: privateAccount ?? this.privateAccount,
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      language: language ?? this.language,
      videoQuality: videoQuality ?? this.videoQuality,
      theme: theme ?? this.theme,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      saveOriginalPhotos: saveOriginalPhotos ?? this.saveOriginalPhotos,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      allowTagging: allowTagging ?? this.allowTagging,
      status: status ?? this.status,
      error: clearError ? null : error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        notificationsEnabled,
        privateAccount,
        twoFactorAuth,
        language,
        videoQuality,
        theme,
        autoPlayVideos,
        saveOriginalPhotos,
        showActivityStatus,
        allowTagging,
        status,
        error,
        isLoading,
        isSaving,
        isDeleting,
        lastUpdated,
      ];
}

enum SettingsStatus {
  initial,
  loading,
  saving,
  deleting,
  success,
  error,
}
