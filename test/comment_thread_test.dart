import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/widgets/comments/comment_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('groupCommentsIntoThreads', () {
    test('groups replies inside the parent thread and sorts oldest first', () {
      final now = DateTime.parse('2026-06-16T12:00:00Z');

      final comments = [
        Comment(
          id: 2,
          userId: 2,
          userName: 'Reply later',
          userAvatar: '',
          content: 'Later reply',
          parentCommentId: 1,
          createdAt: now.add(const Duration(minutes: 3)),
        ),
        Comment(
          id: 1,
          userId: 1,
          userName: 'Parent',
          userAvatar: '',
          content: 'Root comment',
          createdAt: now,
        ),
        Comment(
          id: 3,
          userId: 3,
          userName: 'Reply earlier',
          userAvatar: '',
          content: 'Earlier reply',
          parentCommentId: 1,
          createdAt: now.add(const Duration(minutes: 1)),
        ),
      ];

      final threads = groupCommentsIntoThreads(comments);

      expect(threads, hasLength(1));
      expect(threads.first.parent.id, 1);
      expect(threads.first.replies.map((item) => item.id), [3, 2]);
    });
  });
}
