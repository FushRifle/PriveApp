import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:clique/core/services/settings/settings_service.dart';

class AppLockSettings {
  final bool enabled;
  final bool biometricEnabled;
  final bool pinEnabled;
  final int timeoutSeconds;
  final String? pin;

  const AppLockSettings({
    required this.enabled,
    required this.biometricEnabled,
    required this.pinEnabled,
    required this.timeoutSeconds,
    this.pin,
  });
}

class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _enabledKey = 'app_lock_enabled';
  static const String _biometricKey = 'app_lock_biometric_enabled';
  static const String _pinEnabledKey = 'app_lock_pin_enabled';
  static const String _pinKey = 'app_lock_pin_value';
  static const String _timeoutKey = 'app_lock_timeout_seconds';

  final SettingsService _settingsService = SettingsService();

  Future<AppLockSettings> load() async {
    final remote = await _settingsService.getSettings();
    final enabled = _readBool(remote['appLockEnabled']) ??
        await _readBoolKey(_enabledKey) ??
        false;
    final biometricEnabled = _readBool(remote['appLockBiometricEnabled']) ??
        await _readBoolKey(_biometricKey) ??
        false;
    final pinEnabled = _readBool(remote['appLockPinEnabled']) ??
        await _readBoolKey(_pinEnabledKey) ??
        false;
    final timeoutSeconds = _readInt(remote['appLockTimeoutSeconds']) ??
        await _readIntKey(_timeoutKey) ??
        0;
    final pin = await _storage.read(key: _pinKey);

    await _cacheLocal(
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pin,
    );

    return AppLockSettings(
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pin,
    );
  }

  Future<AppLockSettings> loadCached() async {
    final enabled = await _readBoolKey(_enabledKey) ?? false;
    final biometricEnabled = await _readBoolKey(_biometricKey) ?? false;
    final pinEnabled = await _readBoolKey(_pinEnabledKey) ?? false;
    final timeoutSeconds = await _readIntKey(_timeoutKey) ?? 0;
    final pin = await _storage.read(key: _pinKey);

    return AppLockSettings(
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pin,
    );
  }

  Future<AppLockSettings> save({
    required bool biometricEnabled,
    required bool pinEnabled,
    required int timeoutSeconds,
    String? pin,
  }) async {
    final enabled = biometricEnabled || pinEnabled;

    await _settingsService.updateSettings(
      appLockEnabled: enabled,
      appLockBiometricEnabled: biometricEnabled,
      appLockPinEnabled: pinEnabled,
      appLockTimeoutSeconds: timeoutSeconds,
    );

    await _cacheLocal(
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pin,
    );

    return AppLockSettings(
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pin,
    );
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }

  Future<bool> isEnabled() async {
    return (await load()).enabled;
  }

  Future<String?> getPin() async {
    return _storage.read(key: _pinKey);
  }

  Future<void> _cacheLocal({
    required bool enabled,
    required bool biometricEnabled,
    required bool pinEnabled,
    required int timeoutSeconds,
    String? pin,
  }) async {
    await Future.wait([
      _storage.write(key: _enabledKey, value: enabled.toString()),
      _storage.write(key: _biometricKey, value: biometricEnabled.toString()),
      _storage.write(key: _pinEnabledKey, value: pinEnabled.toString()),
      _storage.write(key: _timeoutKey, value: timeoutSeconds.toString()),
    ]);

    if (pin != null) {
      await _storage.write(key: _pinKey, value: pin);
    } else if (!pinEnabled) {
      await _storage.delete(key: _pinKey);
    }
  }

  Future<bool?> _readBoolKey(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  Future<int?> _readIntKey(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
