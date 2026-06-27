import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_cache_keys.dart';

class LocalCacheService {
  LocalCacheService._();

  static bool _initialized = false;
  static Future<void>? _initializationFuture;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  static const _appLockHiveKey = 'hive_app_lock_cipher_key';

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    final existing = _initializationFuture;
    if (existing != null) return existing;

    final initialization = _initializeBoxes();
    _initializationFuture = initialization;
    try {
      await initialization;
    } finally {
      if (!_initialized && identical(_initializationFuture, initialization)) {
        _initializationFuture = null;
      }
    }
  }

  static Future<void> _initializeBoxes() async {
    try {
      await Hive.initFlutter();
      final appLockCipher = HiveAesCipher(await _appLockCipherKey());
      await Future.wait([
        Hive.openBox<dynamic>(HiveCacheKeys.feedBox),
        Hive.openBox<dynamic>(HiveCacheKeys.metaBox),
        Hive.openBox<dynamic>(HiveCacheKeys.chatBox),
        Hive.openBox<dynamic>(HiveCacheKeys.notificationBox),
        Hive.openBox<dynamic>(HiveCacheKeys.postDraftBox),
        Hive.openBox<dynamic>(
          HiveCacheKeys.appLockBox,
          encryptionCipher: appLockCipher,
        ),
      ]);
      _initialized = true;
    } catch (e, stackTrace) {
      debugPrint('LocalCacheService init failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _initialized = false;
    }
  }

  static Box<dynamic>? box(String name) {
    if (!_initialized) return null;
    if (!Hive.isBoxOpen(name)) return null;
    return Hive.box<dynamic>(name);
  }

  static Future<void> clearAll() async {
    if (!_initialized) return;

    await Future.wait([
      box(HiveCacheKeys.feedBox)?.clear() ?? Future.value(0),
      box(HiveCacheKeys.metaBox)?.clear() ?? Future.value(0),
      box(HiveCacheKeys.chatBox)?.clear() ?? Future.value(0),
      box(HiveCacheKeys.notificationBox)?.clear() ?? Future.value(0),
      box(HiveCacheKeys.postDraftBox)?.clear() ?? Future.value(0),
    ]);
  }

  static Future<Uint8List> _appLockCipherKey() async {
    final existing = await _secureStorage.read(key: _appLockHiveKey);
    if (existing != null && existing.isNotEmpty) {
      return Uint8List.fromList(base64Decode(existing));
    }

    final random = Random.secure();
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _secureStorage.write(key: _appLockHiveKey, value: base64Encode(key));
    return key;
  }
}
