import 'dart:io';

import 'package:clique/core/local_cache/hive_cache_keys.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import 'package:clique/core/models/create_post_models.dart';

class PostDraftService {
  static const _key = 'post_drafts';

  List<Map<String, dynamic>> getDrafts() {
    _migrateLegacyDrafts();
    final box = LocalCacheService.box(HiveCacheKeys.postDraftBox);
    final raw = box?.get(_key);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
      ..sort((a, b) => (b['updatedAt'] ?? '').toString().compareTo(
            (a['updatedAt'] ?? '').toString(),
          ));
  }

  Future<void> upsertDraft(Map<String, dynamic> draft) async {
    final box = LocalCacheService.box(HiveCacheKeys.postDraftBox);
    if (box == null) return;

    final id = draft['id']?.toString();
    if (id == null || id.isEmpty) return;

    final drafts = getDrafts();
    final next = [
      draft,
      ...drafts.where((item) => item['id']?.toString() != id),
    ].take(20).toList();

    await box.put(_key, next);
  }

  Future<void> deleteDraft(String id) async {
    final box = LocalCacheService.box(HiveCacheKeys.postDraftBox);
    if (box == null) return;
    final drafts =
        getDrafts().where((item) => item['id']?.toString() != id).toList();
    await box.put(_key, drafts);
  }

  void _migrateLegacyDrafts() {
    final target = LocalCacheService.box(HiveCacheKeys.postDraftBox);
    final legacy = LocalCacheService.box(HiveCacheKeys.feedBox);
    if (target == null || legacy == null || target.containsKey(_key)) return;

    final raw = legacy.get(_key);
    if (raw is List && raw.isNotEmpty) {
      target.put(_key, raw);
    }
    legacy.delete(_key);
  }

  static List<MediaItem> mediaItemsFromDraft(Map<String, dynamic> draft) {
    final raw = draft['mediaItems'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      final path = map['path']?.toString() ?? '';
      final type = map['type'] == 'video' ? MediaType.video : MediaType.image;
      return MediaItem(
        file: path.isEmpty ? null : File(path),
        fileName: map['fileName']?.toString(),
        type: type,
      );
    }).where((item) {
      final file = item.file;
      return file != null && file.existsSync();
    }).toList();
  }
}
