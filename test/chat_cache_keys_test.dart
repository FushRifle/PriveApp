import 'package:clique/core/services/chat/chat_cache_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat cache keys are isolated by owner and conversation', () {
    expect(ChatCacheKeys.conversations(11),
        isNot(ChatCacheKeys.conversations(22)));
    expect(ChatCacheKeys.messages(11, 7), isNot(ChatCacheKeys.messages(22, 7)));
    expect(ChatCacheKeys.messages(11, 7), isNot(ChatCacheKeys.messages(11, 8)));
    expect(ChatCacheKeys.draft(11, 7), isNot(ChatCacheKeys.draft(22, 7)));
    expect(
        ChatCacheKeys.cliqueBot(11, 7), isNot(ChatCacheKeys.cliqueBot(22, 7)));
  });

  test('pending retry ownership rejects legacy and other-user keys', () {
    expect(ChatCacheKeys.ownsMessageKey(ChatCacheKeys.messages(11, 7), 11),
        isTrue);
    expect(ChatCacheKeys.ownsMessageKey(ChatCacheKeys.messages(22, 7), 11),
        isFalse);
    expect(ChatCacheKeys.ownsMessageKey('chat_messages_7', 11), isFalse);
  });
}
