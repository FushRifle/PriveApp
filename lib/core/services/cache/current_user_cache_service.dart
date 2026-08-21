import 'package:clique/core/local_cache/hive_cache_keys.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';

class CurrentUserCacheService {
  const CurrentUserCacheService._();

  static Future<Map<String, dynamic>?> read(String authUserId) async {
    final normalizedId = authUserId.trim();
    if (normalizedId.isEmpty) return null;

    final value = LocalCacheService.box(HiveCacheKeys.metaBox)?.get(
      _key(normalizedId),
    );
    if (value is! Map) return null;

    return value.map(
      (key, item) => MapEntry(key.toString(), _normalizeValue(item)),
    );
  }

  static Future<void> write(
    String authUserId,
    Map<String, dynamic> user,
  ) async {
    final normalizedId = authUserId.trim();
    if (normalizedId.isEmpty || user.isEmpty) return;

    await LocalCacheService.box(HiveCacheKeys.metaBox)?.put(
      _key(normalizedId),
      _normalizeValue(user),
    );
  }

  static Future<void> delete(String authUserId) async {
    final normalizedId = authUserId.trim();
    if (normalizedId.isEmpty) return;
    await LocalCacheService.box(HiveCacheKeys.metaBox)?.delete(
      _key(normalizedId),
    );
  }

  static String _key(String authUserId) =>
      '${HiveCacheKeys.currentUserPrefix}_$authUserId';

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _normalizeValue(item)),
      );
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    return value;
  }
}
