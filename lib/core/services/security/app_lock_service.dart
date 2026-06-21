import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:clique/core/local_cache/hive_cache_keys.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import 'package:clique/core/services/settings/settings_service.dart';

class AppLockSettings {
  final bool enabled;
  final bool biometricEnabled;
  final bool pinEnabled;
  final int timeoutSeconds;
  final String? pin;
  final String lastSyncStatus;

  const AppLockSettings({
    required this.enabled,
    required this.biometricEnabled,
    required this.pinEnabled,
    required this.timeoutSeconds,
    this.pin,
    this.lastSyncStatus = AppLockSyncStatus.synced,
  });
}

class AppLockSyncStatus {
  const AppLockSyncStatus._();

  static const synced = 'synced';
  static const pending = 'pending';
  static const failed = 'failed';
}

class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  static const String _enabledKey = 'app_lock_enabled';
  static const String _biometricKey = 'app_lock_biometric_enabled';
  static const String _pinEnabledKey = 'app_lock_pin_enabled';
  static const String _pinKey = 'app_lock_pin_value';
  static const String _timeoutKey = 'app_lock_timeout_seconds';
  static const String _syncStatusKey = 'app_lock_sync_status';
  static const String _pendingPayloadKey = 'app_lock_pending_payload';

  final SettingsService _settingsService = SettingsService();
  Timer? _syncRetryTimer;
  bool _syncInFlight = false;

  Future<AppLockSettings> load({int? userId}) async {
    final cached = await loadCached(userId: userId);
    unawaited(syncPending(userId: userId));
    return cached;
  }

  Future<AppLockSettings> loadCached({int? userId}) async {
    final box = _box();
    final enabled = _readCachedBool(box, _enabledKey, userId) ?? false;
    final biometricEnabled =
        _readCachedBool(box, _biometricKey, userId) ?? false;
    final pinEnabled = _readCachedBool(box, _pinEnabledKey, userId) ?? false;
    final timeoutSeconds = _readCachedInt(box, _timeoutKey, userId) ?? 0;
    final pin = await getPin(userId: userId);
    final lastSyncStatus = _readCachedString(box, _syncStatusKey, userId) ??
        AppLockSyncStatus.synced;

    return AppLockSettings(
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pinEnabled ? pin : null,
      lastSyncStatus: lastSyncStatus,
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
      syncStatus: AppLockSyncStatus.pending,
      pendingPayload: {
        'appLockEnabled': enabled,
        'appLockBiometricEnabled': biometricEnabled,
        'appLockPinEnabled': pinEnabled,
        'appLockTimeoutSeconds': timeoutSeconds,
      },
    );

    unawaited(syncPending(userId: userId));

    return AppLockSettings(
      enabled: enabled,
      biometricEnabled: biometricEnabled,
      pinEnabled: pinEnabled,
      timeoutSeconds: timeoutSeconds,
      pin: pinEnabled ? pin : null,
      lastSyncStatus: AppLockSyncStatus.pending,
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
    final box = _box();
    await box.delete(_scopedKey(_pinKey, userId));
    await box.put(_scopedKey(_pinEnabledKey, userId), false);
  }

  Future<bool> isEnabled({int? userId}) async {
    return (await loadCached(userId: userId)).enabled;
  }

  Future<String?> getPin({int? userId}) async {
    final box = _box();
    final scopedPin = box.get(_scopedKey(_pinKey, userId))?.toString();
    if ((scopedPin ?? '').isNotEmpty || userId == null) {
      return scopedPin;
    }
    return box.get(_scopedKey(_pinKey, null))?.toString();
  }

  Future<void> syncPending({int? userId}) async {
    final box = _box();
    final payload = _readPendingPayload(box, userId);
    if (payload == null || _syncInFlight) return;

    _syncInFlight = true;
    try {
      await _settingsService.updateSettings(
        appLockEnabled: payload['appLockEnabled'] as bool?,
        appLockBiometricEnabled: payload['appLockBiometricEnabled'] as bool?,
        appLockPinEnabled: payload['appLockPinEnabled'] as bool?,
        appLockTimeoutSeconds: payload['appLockTimeoutSeconds'] as int?,
      );
      await box.put(
        _scopedKey(_syncStatusKey, userId),
        AppLockSyncStatus.synced,
      );
      await box.delete(_scopedKey(_pendingPayloadKey, userId));
      _syncRetryTimer?.cancel();
      _syncRetryTimer = null;
    } catch (error) {
      debugPrint('App lock sync failed: $error');
      await box.put(
        _scopedKey(_syncStatusKey, userId),
        AppLockSyncStatus.failed,
      );
      _scheduleRetry(userId);
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _cacheLocal({
    required int? userId,
    required bool enabled,
    required bool biometricEnabled,
    required bool pinEnabled,
    required int timeoutSeconds,
    String? pin,
    String? syncStatus,
    Map<String, dynamic>? pendingPayload,
  }) async {
    final box = _box();
    await Future.wait([
      box.put(_scopedKey(_enabledKey, userId), enabled),
      box.put(_scopedKey(_biometricKey, userId), biometricEnabled),
      box.put(_scopedKey(_pinEnabledKey, userId), pinEnabled),
      box.put(_scopedKey(_timeoutKey, userId), timeoutSeconds),
      if (syncStatus != null)
        box.put(_scopedKey(_syncStatusKey, userId), syncStatus),
      if (pendingPayload != null)
        box.put(_scopedKey(_pendingPayloadKey, userId), pendingPayload),
    ]);

    if (pin != null) {
      await box.put(_scopedKey(_pinKey, userId), pin);
      if (userId != null) {
        await box.put(_scopedKey(_pinKey, null), pin);
      }
    } else if (!pinEnabled) {
      await box.delete(_scopedKey(_pinKey, userId));
      if (userId != null) {
        await box.delete(_scopedKey(_pinKey, null));
      }
    }
  }

  Box<dynamic> _box() {
    final box = LocalCacheService.box(HiveCacheKeys.appLockBox);
    if (box == null) {
      throw StateError('App lock cache is not initialized');
    }
    return box;
  }

  String _scopedKey(String base, int? userId) {
    final suffix =
        (userId != null && userId > 0) ? userId.toString() : 'global';
    return '${base}_$suffix';
  }

  bool? _readCachedBool(Box<dynamic> box, String key, int? userId) {
    final scoped = box.get(_scopedKey(key, userId));
    if (scoped != null || userId == null) return _readBool(scoped);
    return _readBool(box.get(_scopedKey(key, null)));
  }

  int? _readCachedInt(Box<dynamic> box, String key, int? userId) {
    final scoped = box.get(_scopedKey(key, userId));
    if (scoped != null || userId == null) return _readInt(scoped);
    return _readInt(box.get(_scopedKey(key, null)));
  }

  String? _readCachedString(Box<dynamic> box, String key, int? userId) {
    final scoped = box.get(_scopedKey(key, userId));
    if (scoped != null || userId == null) return scoped.toString();
    return box.get(_scopedKey(key, null))?.toString();
  }

  Map<String, dynamic>? _readPendingPayload(Box<dynamic> box, int? userId) {
    final value = box.get(_scopedKey(_pendingPayloadKey, userId)) ??
        (userId != null ? box.get(_scopedKey(_pendingPayloadKey, null)) : null);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void _scheduleRetry(int? userId) {
    _syncRetryTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(syncPending(userId: userId)),
    );
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
