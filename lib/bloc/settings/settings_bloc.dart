import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/settings/settings_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService = SettingsService();

  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
    on<ToggleNotifications>(_onToggleNotifications);
    on<TogglePrivateAccount>(_onTogglePrivateAccount);
    on<ToggleTwoFactorAuth>(_onToggleTwoFactorAuth);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeVideoQuality>(_onChangeVideoQuality);
    on<ToggleAutoPlayVideos>(_onToggleAutoPlayVideos);
    on<ToggleSaveOriginalPhotos>(_onToggleSaveOriginalPhotos);
    on<ToggleActivityStatus>(_onToggleActivityStatus);
    on<ToggleTagging>(_onToggleTagging);
    on<ResetSettings>(_onResetSettings);
    on<ClearSettingsError>(_onClearSettingsError);
    on<DeleteAccountSettings>(_onDeleteAccountSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: SettingsStatus.loading,
      isLoading: true,
      error: null,
    ));

    try {
      final settings = await _settingsService.getSettings();

      emit(SettingsState(
        notificationsEnabled: settings['notificationsEnabled'] ?? true,
        privateAccount: settings['privateAccount'] ?? false,
        twoFactorAuth: settings['twoFactorAuth'] ?? false,
        language: settings['language']?.toString() ?? 'en',
        videoQuality: settings['videoQuality']?.toString() ?? 'auto',
        theme: settings['theme']?.toString() ?? 'system',
        autoPlayVideos: settings['autoPlayVideos'] ?? true,
        saveOriginalPhotos: settings['saveOriginalPhotos'] ?? false,
        showActivityStatus: settings['showActivityStatus'] ?? true,
        allowTagging: settings['allowTagging'] ?? true,
        status: SettingsStatus.success,
        isLoading: false,
        error: null,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: SettingsStatus.saving,
      isSaving: true,
      error: null,
    ));

    try {
      // Optimistically update local state
      final updatedState = state.copyWith(
        notificationsEnabled:
            event.notificationsEnabled ?? state.notificationsEnabled,
        privateAccount: event.privateAccount ?? state.privateAccount,
        twoFactorAuth: event.twoFactorAuth ?? state.twoFactorAuth,
        language: event.language ?? state.language,
        videoQuality: event.videoQuality ?? state.videoQuality,
        theme: event.theme ?? state.theme,
        autoPlayVideos: event.autoPlayVideos ?? state.autoPlayVideos,
        saveOriginalPhotos:
            event.saveOriginalPhotos ?? state.saveOriginalPhotos,
        showActivityStatus:
            event.showActivityStatus ?? state.showActivityStatus,
        allowTagging: event.allowTagging ?? state.allowTagging,
        lastUpdated: DateTime.now(),
      );

      emit(updatedState);

      await _settingsService.updateSettings(
        notificationsEnabled: event.notificationsEnabled,
        privateAccount: event.privateAccount,
        twoFactorAuth: event.twoFactorAuth,
        language: event.language,
        videoQuality: event.videoQuality,
        theme: event.theme,
        autoPlayVideos: event.autoPlayVideos,
        saveOriginalPhotos: event.saveOriginalPhotos,
        showActivityStatus: event.showActivityStatus,
        allowTagging: event.allowTagging,
      );

      emit(updatedState.copyWith(
        status: SettingsStatus.success,
        isSaving: false,
        error: null,
      ));
    } catch (e) {
      // Reload settings to revert optimistic update
      add(LoadSettings());
      emit(state.copyWith(
        status: SettingsStatus.error,
        isSaving: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(notificationsEnabled: event.enabled));
  }

  Future<void> _onTogglePrivateAccount(
    TogglePrivateAccount event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(privateAccount: event.isPrivate));
  }

  Future<void> _onToggleTwoFactorAuth(
    ToggleTwoFactorAuth event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(twoFactorAuth: event.enabled));
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(language: event.language));
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(theme: event.theme));
  }

  Future<void> _onChangeVideoQuality(
    ChangeVideoQuality event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(videoQuality: event.quality));
  }

  Future<void> _onToggleAutoPlayVideos(
    ToggleAutoPlayVideos event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(autoPlayVideos: event.autoPlay));
  }

  Future<void> _onToggleSaveOriginalPhotos(
    ToggleSaveOriginalPhotos event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(saveOriginalPhotos: event.save));
  }

  Future<void> _onToggleActivityStatus(
    ToggleActivityStatus event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(showActivityStatus: event.show));
  }

  Future<void> _onToggleTagging(
    ToggleTagging event,
    Emitter<SettingsState> emit,
  ) async {
    add(UpdateSettings(allowTagging: event.allow));
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    // Reset to default values
    add(UpdateSettings(
      notificationsEnabled: true,
      privateAccount: false,
      twoFactorAuth: false,
      language: 'en',
      videoQuality: 'auto',
      theme: 'system',
      autoPlayVideos: true,
      saveOriginalPhotos: false,
      showActivityStatus: true,
      allowTagging: true,
    ));
  }

  void _onClearSettingsError(
    ClearSettingsError event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  Future<void> _onDeleteAccountSettings(
    DeleteAccountSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: SettingsStatus.deleting,
      isDeleting: true,
      error: null,
    ));

    try {
      await _settingsService.deleteSettings();
      emit(const SettingsState(
        status: SettingsStatus.success,
        isDeleting: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        isDeleting: false,
        error: e.toString(),
      ));
    }
  }
}
