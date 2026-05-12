part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

// Load settings
class LoadSettings extends SettingsEvent {}

// Update settings
class UpdateSettings extends SettingsEvent {
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

  const UpdateSettings({
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
  });

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
      ];
}

// Toggle specific settings (convenience events)
class ToggleNotifications extends SettingsEvent {
  final bool enabled;

  const ToggleNotifications({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class TogglePrivateAccount extends SettingsEvent {
  final bool isPrivate;

  const TogglePrivateAccount({required this.isPrivate});

  @override
  List<Object?> get props => [isPrivate];
}

class ToggleTwoFactorAuth extends SettingsEvent {
  final bool enabled;

  const ToggleTwoFactorAuth({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class ChangeLanguage extends SettingsEvent {
  final String language;

  const ChangeLanguage({required this.language});

  @override
  List<Object?> get props => [language];
}

class ChangeTheme extends SettingsEvent {
  final String theme;

  const ChangeTheme({required this.theme});

  @override
  List<Object?> get props => [theme];
}

class ChangeVideoQuality extends SettingsEvent {
  final String quality;

  const ChangeVideoQuality({required this.quality});

  @override
  List<Object?> get props => [quality];
}

class ToggleAutoPlayVideos extends SettingsEvent {
  final bool autoPlay;

  const ToggleAutoPlayVideos({required this.autoPlay});

  @override
  List<Object?> get props => [autoPlay];
}

class ToggleSaveOriginalPhotos extends SettingsEvent {
  final bool save;

  const ToggleSaveOriginalPhotos({required this.save});

  @override
  List<Object?> get props => [save];
}

class ToggleActivityStatus extends SettingsEvent {
  final bool show;

  const ToggleActivityStatus({required this.show});

  @override
  List<Object?> get props => [show];
}

class ToggleTagging extends SettingsEvent {
  final bool allow;

  const ToggleTagging({required this.allow});

  @override
  List<Object?> get props => [allow];
}

// Reset settings to default
class ResetSettings extends SettingsEvent {}

// Clear settings error
class ClearSettingsError extends SettingsEvent {}

// Delete all settings (account)
class DeleteAccountSettings extends SettingsEvent {}
