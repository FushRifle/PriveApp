import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

import 'package:clique/core/services/security/app_lock_service.dart';
import 'package:clique/core/services/settings/settings_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService = SettingsService();
  final AppLockService _appLockService = AppLockService.instance;

  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
    on<ToggleNotifications>(_onToggleNotifications);
    on<TogglePrivateAccount>(_onTogglePrivateAccount);
    on<ToggleTwoFactorAuth>(_onToggleTwoFactorAuth);
    on<ToggleAppLock>(_onToggleAppLock);
    on<ToggleAppLockBiometric>(_onToggleAppLockBiometric);
    on<ToggleAppLockPin>(_onToggleAppLockPin);
    on<ChangeAppLockTimeout>(_onChangeAppLockTimeout);
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
    final cachedLock = await _appLockService.loadCached(userId: event.userId);

    if (!event.silent) {
      emit(state.copyWith(
        appLockEnabled: cachedLock.enabled,
        appLockBiometricEnabled: cachedLock.biometricEnabled,
        appLockPinEnabled: cachedLock.pinEnabled,
        appLockTimeoutSeconds: cachedLock.timeoutSeconds,
        status: SettingsStatus.loading,
        isLoading: true,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(
        appLockEnabled: cachedLock.enabled,
        appLockBiometricEnabled: cachedLock.biometricEnabled,
        appLockPinEnabled: cachedLock.pinEnabled,
        appLockTimeoutSeconds: cachedLock.timeoutSeconds,
        clearError: true,
      ));
    }

    try {
      final settings = await _settingsService.getSettings();

      emit(SettingsState(
        notificationsEnabled: settings['notificationsEnabled'] ?? true,
        privateAccount: settings['privateAccount'] ?? false,
        twoFactorAuth: settings['twoFactorAuth'] ?? false,
        appLockEnabled: cachedLock.enabled,
        appLockBiometricEnabled: cachedLock.biometricEnabled,
        appLockPinEnabled: cachedLock.pinEnabled,
        appLockTimeoutSeconds: cachedLock.timeoutSeconds,
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
    final previousState = state;

    emit(state.copyWith(
      status: SettingsStatus.saving,
      isSaving: true,
      clearError: true,
    ));

    final updatedState = state.copyWith(
      notificationsEnabled:
          event.notificationsEnabled ?? state.notificationsEnabled,
      privateAccount: event.privateAccount ?? state.privateAccount,
      twoFactorAuth: event.twoFactorAuth ?? state.twoFactorAuth,
      appLockEnabled: event.appLockEnabled ?? state.appLockEnabled,
      appLockBiometricEnabled:
          event.appLockBiometricEnabled ?? state.appLockBiometricEnabled,
      appLockPinEnabled: event.appLockPinEnabled ?? state.appLockPinEnabled,
      appLockTimeoutSeconds:
          event.appLockTimeoutSeconds ?? state.appLockTimeoutSeconds,
      language: event.language ?? state.language,
      videoQuality: event.videoQuality ?? state.videoQuality,
      theme: event.theme ?? state.theme,
      autoPlayVideos: event.autoPlayVideos ?? state.autoPlayVideos,
      saveOriginalPhotos: event.saveOriginalPhotos ?? state.saveOriginalPhotos,
      showActivityStatus: event.showActivityStatus ?? state.showActivityStatus,
      allowTagging: event.allowTagging ?? state.allowTagging,
      lastUpdated: DateTime.now(),
    );

    try {
      emit(updatedState);

      if (_hasAppLockChanges(event)) {
        await _appLockService.save(
          userId: event.userId,
          biometricEnabled: updatedState.getAppLockBiometricEnabled,
          pinEnabled: updatedState.getAppLockPinEnabled,
          timeoutSeconds: updatedState.getAppLockTimeoutSeconds,
        );
      }

      if (_hasBackendSettingsChanges(event)) {
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
      }

      emit(updatedState.copyWith(
        status: SettingsStatus.success,
        isSaving: false,
        clearError: true,
      ));
    } catch (e) {
      if (_hasAppLockChanges(event) && !_hasBackendSettingsChanges(event)) {
        unawaited(_appLockService.syncPending(userId: event.userId));
        emit(updatedState.copyWith(
          status: SettingsStatus.success,
          isSaving: false,
          clearError: true,
        ));
        return;
      }
      emit(previousState.copyWith(
        status: SettingsStatus.error,
        isSaving: false,
        error: e.toString(),
      ));
    }
  }

  bool _hasAppLockChanges(UpdateSettings event) {
    return event.appLockEnabled != null ||
        event.appLockBiometricEnabled != null ||
        event.appLockPinEnabled != null ||
        event.appLockTimeoutSeconds != null;
  }

  bool _hasBackendSettingsChanges(UpdateSettings event) {
    return event.notificationsEnabled != null ||
        event.privateAccount != null ||
        event.twoFactorAuth != null ||
        event.language != null ||
        event.videoQuality != null ||
        event.theme != null ||
        event.autoPlayVideos != null ||
        event.saveOriginalPhotos != null ||
        event.showActivityStatus != null ||
        event.allowTagging != null;
  }

  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(notificationsEnabled: event.enabled),
      emit,
    );
  }

  Future<void> _onTogglePrivateAccount(
    TogglePrivateAccount event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(privateAccount: event.isPrivate),
      emit,
    );
  }

  Future<void> _onToggleTwoFactorAuth(
    ToggleTwoFactorAuth event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(twoFactorAuth: event.enabled),
      emit,
    );
  }

  Future<void> _onToggleAppLock(
    ToggleAppLock event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(
        appLockEnabled: event.enabled,
        appLockBiometricEnabled:
            event.enabled ? state.getAppLockBiometricEnabled : false,
        appLockPinEnabled: event.enabled ? state.getAppLockPinEnabled : false,
        appLockTimeoutSeconds:
            event.enabled ? state.getAppLockTimeoutSeconds : 0,
      ),
      emit,
    );
  }

  Future<void> _onToggleAppLockBiometric(
    ToggleAppLockBiometric event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(
        appLockBiometricEnabled: event.enabled,
        appLockEnabled: event.enabled || state.getAppLockPinEnabled,
      ),
      emit,
    );
  }

  Future<void> _onToggleAppLockPin(
    ToggleAppLockPin event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(
        appLockPinEnabled: event.enabled,
        appLockEnabled: event.enabled || state.getAppLockBiometricEnabled,
      ),
      emit,
    );
  }

  Future<void> _onChangeAppLockTimeout(
    ChangeAppLockTimeout event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(
        appLockTimeoutSeconds: event.seconds,
        appLockEnabled: state.getAppLockEnabled,
      ),
      emit,
    );
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(language: event.language),
      emit,
    );
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(theme: event.theme),
      emit,
    );
  }

  Future<void> _onChangeVideoQuality(
    ChangeVideoQuality event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(videoQuality: event.quality),
      emit,
    );
  }

  Future<void> _onToggleAutoPlayVideos(
    ToggleAutoPlayVideos event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(autoPlayVideos: event.autoPlay),
      emit,
    );
  }

  Future<void> _onToggleSaveOriginalPhotos(
    ToggleSaveOriginalPhotos event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(saveOriginalPhotos: event.save),
      emit,
    );
  }

  Future<void> _onToggleActivityStatus(
    ToggleActivityStatus event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(showActivityStatus: event.show),
      emit,
    );
  }

  Future<void> _onToggleTagging(
    ToggleTagging event,
    Emitter<SettingsState> emit,
  ) async {
    await _onUpdateSettings(
      UpdateSettings(allowTagging: event.allow),
      emit,
    );
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    // Reset to default values
    await _onUpdateSettings(
      const UpdateSettings(
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
      ),
      emit,
    );
  }

  void _onClearSettingsError(
    ClearSettingsError event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  Future<void> _onDeleteAccountSettings(
    DeleteAccountSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: SettingsStatus.deleting,
      isDeleting: true,
      clearError: true,
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
