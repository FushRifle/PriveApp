import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_cache_keys.dart';

class LocalCacheService {
  LocalCacheService._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      await Future.wait([
        Hive.openBox<dynamic>(HiveCacheKeys.feedBox),
        Hive.openBox<dynamic>(HiveCacheKeys.metaBox),
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
    ]);
  }
}
