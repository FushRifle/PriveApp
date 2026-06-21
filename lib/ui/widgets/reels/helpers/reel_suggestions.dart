import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/ui/widgets/common/token_suggestion_field.dart';

Future<List<ComposerTokenSuggestion>> suggestReelComposerTokens(
  ComposerTokenType type,
  String query,
) async {
  final normalizedQuery = query.trim().toLowerCase();
  final userService = UserService();
  final feedService = FeedService();

  try {
    if (type == ComposerTokenType.mention) {
      if (normalizedQuery.isEmpty) {
        return const [];
      }

      final users = await userService.searchUsers(
        normalizedQuery,
        limit: 8,
      );

      return users
          .map((user) {
            final name = (user['name'] ?? user['displayName'] ?? 'User')
                .toString()
                .trim();
            final username =
                (user['username'] ?? user['handle'] ?? '').toString().trim();
            final bioValue = user['bio']?.toString();
            final subtitle = bioValue != null ? bioValue.trim() : '';

            return ComposerTokenSuggestion(
              value: username.isNotEmpty ? username : name.replaceAll(' ', '_'),
              label: username.isNotEmpty ? '@$username' : '@$name',
              subtitle: subtitle.isNotEmpty ? subtitle : null,
            );
          })
          .where((suggestion) => suggestion.value.isNotEmpty)
          .toList();
    }

    final hashtags = await feedService.getTrendingHashtags(limit: 12);
    final seen = <String>{};
    final values = <String>[
      ...hashtags.map((item) => item['tag']?.toString().trim() ?? ''),
      'reels',
      'video',
      'viral',
      'trending',
      'funny',
      'music',
      'dance',
      'edit',
    ]
        .where((tag) => tag.isNotEmpty)
        .where((tag) => seen.add(tag.toLowerCase()))
        .toList();

    final filtered = normalizedQuery.isEmpty
        ? values
        : values.where((tag) => tag.toLowerCase().contains(normalizedQuery));

    return filtered
        .map(
          (tag) => ComposerTokenSuggestion(
            value: tag.startsWith('#') ? tag.substring(1) : tag,
            label: '#$tag',
            subtitle: 'Hashtag',
          ),
        )
        .toList();
  } catch (_) {
    return const [];
  }
}