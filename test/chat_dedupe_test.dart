import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mergeMessages removes pending sender copy when delivery arrives', () {
    final bloc = ChatBloc();
    addTearDown(bloc.close);

    final createdAt = DateTime.parse('2026-06-25T12:00:00Z');
    final pending = MessageModel(
      id: -1,
      conversationId: 7,
      clientMessageId: 'client-1',
      senderId: 1,
      receiverId: 2,
      message: 'hello',
      messageType: 'text',
      isRead: false,
      isOwn: true,
      createdAt: createdAt,
    );
    final delivered = MessageModel(
      id: 42,
      conversationId: 7,
      clientMessageId: 'client-1',
      senderId: 1,
      receiverId: 2,
      message: 'hello',
      messageType: 'text',
      isRead: false,
      isOwn: true,
      createdAt: createdAt.add(const Duration(seconds: 1)),
    );

    final merged = bloc.mergeMessagesForTesting([pending, delivered]);

    expect(merged, hasLength(1));
    expect(merged.single.id, 42);
  });
}
