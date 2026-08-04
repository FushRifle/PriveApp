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

  test('mergeMessages keeps pending message when fetched page is stale', () {
    final bloc = ChatBloc();
    addTearDown(bloc.close);

    final createdAt = DateTime.parse('2026-06-25T12:00:00Z');
    final olderFetched = MessageModel(
      id: 10,
      conversationId: 7,
      senderId: 2,
      receiverId: 1,
      message: 'older',
      messageType: 'text',
      isRead: true,
      isOwn: false,
      createdAt: createdAt.subtract(const Duration(minutes: 1)),
    );
    final pending = MessageModel(
      id: -99,
      conversationId: 7,
      clientMessageId: 'client-pending',
      senderId: 1,
      receiverId: 2,
      message: 'still sending',
      messageType: 'text',
      isRead: false,
      isOwn: true,
      createdAt: createdAt,
    );

    final merged = bloc.mergeMessagesForTesting([olderFetched, pending]);

    expect(merged, hasLength(2));
    expect(merged.first.id, -99);
    expect(merged.any((message) => message.message == 'older'), isTrue);
  });

  test('mergeMessages dedupes delivered by id and prefers latest copy', () {
    final bloc = ChatBloc();
    addTearDown(bloc.close);

    final createdAt = DateTime.parse('2026-06-25T12:00:00Z');
    final stale = MessageModel(
      id: 42,
      conversationId: 7,
      senderId: 1,
      receiverId: 2,
      message: 'hello',
      messageType: 'text',
      isRead: false,
      isOwn: true,
      createdAt: createdAt,
    );
    final fresh = stale.copyWith(isRead: true);

    final merged = bloc.mergeMessagesForTesting([stale, fresh]);

    expect(merged, hasLength(1));
    expect(merged.single.isRead, isTrue);
  });

  test('mergeMessages retains a bounded window of the newest messages', () {
    final bloc = ChatBloc();
    addTearDown(bloc.close);

    final start = DateTime.parse('2026-06-25T12:00:00Z');
    final messages = List.generate(
      540,
      (index) => MessageModel(
        id: index + 1,
        conversationId: 7,
        senderId: 1,
        receiverId: 2,
        message: 'message $index',
        messageType: 'text',
        isRead: true,
        isOwn: true,
        createdAt: start.add(Duration(seconds: index)),
      ),
    );

    final merged = bloc.mergeMessagesForTesting(messages);

    expect(merged, hasLength(500));
    expect(merged.first.id, 540);
    expect(merged.last.id, 41);
  });
}
