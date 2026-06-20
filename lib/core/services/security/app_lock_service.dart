import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<AppLockSettings> load({int? userId}) async {
    final cached = await loadCached(userId: userId);

    try {
      final remote = await _settingsService.getSettings();
      final enabled = _readBool(remote['appLockEnabled']) ?? cached.enabled;
      final biometricEnabled = _readBool(remote['appLockBiometricEnabled']) ??
          cached.biometricEnabled;
      final pinEnabled =
          _readBool(remote['appLockPinEnabled']) ?? cached.pinEnabled;
      final timeoutSeconds =
          _readInt(remote['appLockTimeoutSeconds']) ?? cached.timeoutSeconds;
      final pin = pinEnabled ? cached.pin : null;

      await _cacheLocal(
        userId: userId,
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
    } catch (_) {
      return cached;
    }
  }

  Future<AppLockSettings> loadCached({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = _readCachedBool(prefs, _enabledKey, userId) ?? false;
    final biometricEnabled =
        _readCachedBool(prefs, _biometricKey, userId) ?? false;
    final pinEnabled = _readCachedBool(prefs, _pinEnabledKey, userId) ?? false;
    final timeoutSeconds = _readCachedInt(prefs, _timeoutKey, userId) ?? 0;
    final pin = await getPin(userId: userId);

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
    int? userId,
  }) async {
    final enabled = biometricEnabled || pinEnabled;

    await _cacheLocal(
      userId: userId,
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pin,
    );

    unawaited(
      _settingsService
          .updateSettings(
            appLockEnabled: enabled,
            appLockBiometricEnabled: biometricEnabled,
            appLockPinEnabled: pinEnabled,
            appLockTimeoutSeconds: timeoutSeconds,
          )
          .then((_) => _cacheLocal(
                userId: userId,
                enabled: enabled,
                biometricEnabled: biometricEnabled,
                pinEnabled: pinEnabled,
                timeoutSeconds: timeoutSeconds,
                pin: pin,
              ))
          .catchError((error) {
        debugPrint('App lock sync failed: $error');
      }),
    );

    return AppLockSettings(
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pin,
    );
  }

  Future<void> cacheLocal({
    required bool biometricEnabled,
    required bool pinEnabled,
    required int timeoutSeconds,
    String? pin,
    int? userId,
  }) {
    return _cacheLocal(
      userId: userId,
      enabled: biometricEnabled || pinEnabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pin,
    );
  }

  Future<void> clearPin({int? userId}) async {
    await _storage.delete(key: _scopedKey(_pinKey, userId));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scopedKey(_pinEnabledKey, userId), false);
  }

  Future<bool> isEnabled({int? userId}) async {
    return (await loadCached(userId: userId)).enabled;
  }

  Future<String?> getPin({int? userId}) async {
    final scopedPin = await _storage.read(key: _scopedKey(_pinKey, userId));
    if ((scopedPin ?? '').isNotEmpty || userId == null) {
      return scopedPin;
    }
    return _storage.read(key: _scopedKey(_pinKey, null));
  }

  Future<void> _cacheLocal({
    required int? userId,
    required bool enabled,
    required bool biometricEnabled,
    required bool pinEnabled,
    required int timeoutSeconds,
    String? pin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_scopedKey(_enabledKey, userId), enabled),
      prefs.setBool(_scopedKey(_biometricKey, userId), biometricEnabled),
      prefs.setBool(_scopedKey(_pinEnabledKey, userId), pinEnabled),
      prefs.setInt(_scopedKey(_timeoutKey, userId), timeoutSeconds),
    ]);

    if (pin != null) {
      await _storage.write(key: _scopedKey(_pinKey, userId), value: pin);
      if (userId != null) {
        await _storage.write(key: _scopedKey(_pinKey, null), value: pin);
      }
    } else if (!pinEnabled) {
      await _storage.delete(key: _scopedKey(_pinKey, userId));
      if (userId != null) {
        await _storage.delete(key: _scopedKey(_pinKey, null));
      }
    }
  }

  String _scopedKey(String base, int? userId) {
    final suffix =
        (userId != null && userId > 0) ? userId.toString() : 'global';
    return '${base}_$suffix';
  }

  bool? _readCachedBool(SharedPreferences prefs, String key, int? userId) {
    final scoped = prefs.getBool(_scopedKey(key, userId));
    if (scoped != null || userId == null) return scoped;
    return prefs.getBool(_scopedKey(key, null));
  }

  int? _readCachedInt(SharedPreferences prefs, String key, int? userId) {
    final scoped = prefs.getInt(_scopedKey(key, userId));
    if (scoped != null || userId == null) return scoped;
    return prefs.getInt(_scopedKey(key, null));
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
