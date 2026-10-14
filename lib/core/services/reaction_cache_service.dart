import 'dart:async';

import 'package:clique/core/local_cache/hive_cache_keys.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';

class CachedReaction {
  final String reaction;
  final int count;
  final DateTime updatedAt;

  const CachedReaction({
    required this.reaction,
    required this.count,
    required this.updatedAt,
  });
}

/// Keeps the viewer's optimistic reaction stable when a list refresh returns
/// an incomplete or briefly stale `myReaction` payload.
class ReactionCacheService {
  ReactionCacheService._();

  static const _keyPrefix = 'viewer_reaction_v1';
  static const _maxAge = Duration(days: 30);

  static String _entryKey(String scope, Object id) => '$_keyPrefix:$scope:$id';

  static CachedReaction? read(String scope, Object id) {
    final raw =
        LocalCacheService.box(HiveCacheKeys.feedBox)?.get(_entryKey(scope, id));
    if (raw is! Map) return null;

    final reaction = raw['reaction']?.toString().trim() ?? '';
    final updatedAt = DateTime.tryParse(raw['updatedAt']?.toString() ?? '');
    if (reaction.isEmpty || updatedAt == null) return null;
    if (DateTime.now().difference(updatedAt) > _maxAge) {
      unawaited(clear(scope, id));
      return null;
    }

    return CachedReaction(
      reaction: reaction,
      count: _readInt(raw['count']),
      updatedAt: updatedAt,
    );
  }

  static Future<void> save(
    String scope,
    Object id, {
    required String reaction,
    required int count,
  }) async {
    final normalized = reaction.trim();
    if (normalized.isEmpty) {
      await clear(scope, id);
      return;
    }

    final box = LocalCacheService.box(HiveCacheKeys.feedBox);
    if (box == null) return;
    await box.put(_entryKey(scope, id), <String, dynamic>{
      'reaction': normalized,
      'count': count,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> clear(String scope, Object id) async {
    final box = LocalCacheService.box(HiveCacheKeys.feedBox);
    if (box == null) return;
    await box.delete(_entryKey(scope, id));
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
