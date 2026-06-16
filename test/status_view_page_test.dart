import 'package:clique/core/models/status_model.dart';
import 'package:clique/ui/pages/main/status/status_view_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('status viewer renders without a StoriesBloc provider', (
    tester,
  ) async {
    final story = Story(
      id: 'story-1',
      userId: 1,
      user: const StoryUser(
        id: 1,
        name: 'Demo User',
        username: 'demo',
        handle: 'demo',
        avatar: '',
      ),
      content: 'Status fallback works',
      attachments: const [],
      time: 'now',
      createdAt: DateTime.parse('2026-06-16T12:00:00Z'),
      expiresAt: DateTime.parse('2026-06-17T12:00:00Z'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StatusViewPage(
          stories: [story],
          initialIndex: 0,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
