import 'package:clique/core/services/friends/friends_service.dart';

/// Keeps profile statistic requests stable across widget rebuilds.
class FollowStatsCache {
  FollowStatsCache._();

  static final FriendsService _service = FriendsService();
  static final Map<String, Future<FollowStats>> _requests = {};

  static Future<FollowStats> load({
    required int userId,
    required bool isOwnProfile,
  }) {
    final key = isOwnProfile ? 'me:$userId' : 'user:$userId';
    return _requests.putIfAbsent(key, () async {
      try {
        return isOwnProfile
            ? await _service.getFollowStats()
            : await _service.getFollowStatsForUser(userId);
      } catch (_) {
        _requests.remove(key);
        rethrow;
      }
    });
  }

  static void invalidate({int? userId, bool includeOwnProfile = true}) {
    if (includeOwnProfile) {
      _requests.removeWhere((key, _) => key.startsWith('me:'));
    }
    if (userId != null) _requests.remove('user:$userId');
  }

  static void clear() => _requests.clear();
}
