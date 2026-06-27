import 'package:clique/core/local_cache/hive_cache_keys.dart';

class ChatCacheKeys {
  const ChatCacheKeys._();

  static String conversations(int ownerId) =>
      '${HiveCacheKeys.chatConversationsPrefix}_$ownerId';

  static String archived(int ownerId) =>
      '${HiveCacheKeys.archivedChatsPrefix}_$ownerId';

  static String messages(int ownerId, int conversationId) =>
      '${HiveCacheKeys.chatMessagesPrefix}_${ownerId}_$conversationId';

  static String draft(int ownerId, int conversationId) =>
      '${HiveCacheKeys.chatDraftPrefix}_${ownerId}_$conversationId';

  static String cliqueBot(int ownerId, int conversationId) =>
      '${HiveCacheKeys.cliqueBotMessagesPrefix}_${ownerId}_$conversationId';

  static bool ownsMessageKey(String key, int ownerId) {
    return key.startsWith('${HiveCacheKeys.chatMessagesPrefix}_${ownerId}_');
  }
}
