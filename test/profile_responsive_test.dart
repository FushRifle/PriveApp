import 'package:clique/core/models/profile_view.dart';
import 'package:clique/ui/widgets/profile/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tabs = [
    ProfileTabItem(label: 'Posts', icon: Icons.grid_view_rounded),
    ProfileTabItem(label: 'Media', icon: Icons.perm_media_outlined),
    ProfileTabItem(label: 'Saved', icon: Icons.bookmark_border_rounded),
    ProfileTabItem(label: 'Drafts', icon: Icons.drafts_outlined),
  ];

  testWidgets('profile tabs fit a narrow screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 700),
            textScaler: TextScaler.linear(2),
          ),
          child: DefaultTabController(
            length: tabs.length,
            child: Builder(
              builder: (context) => Scaffold(
                body: CustomScrollView(
                  slivers: [
                    ProfileStickyTabBar(
                      tabController: DefaultTabController.of(context),
                      tabs: tabs,
                    ),
                    const SliverFillRemaining(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(Tab), findsNWidgets(4));
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
  });

  testWidgets('long profile controls do not overflow a compact layout',
      (tester) async {
    tester.view.physicalSize = const Size(280, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profile = ProfileView(
      id: 1,
      userId: 1,
      displayName: 'A very long display name that must remain contained',
      username: 'an_extremely_long_profile_handle_that_cannot_overflow',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 700),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ProfileIdentityRow(
                    profile: profile,
                    isOwnProfile: true,
                  ),
                  const SizedBox(height: 12),
                  const ProfileInfoChip(
                    icon: Icons.location_on,
                    label:
                        'An unusually long location name that stays in its chip',
                  ),
                  const SizedBox(height: 12),
                  ProfileActionRow(
                    profile: profile,
                    isOwnProfile: false,
                    isFollowing: false,
                    isFollowRequested: false,
                    onToggleFollow: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('FOLLOW'), findsOneWidget);
    expect(find.text('MESSAGE'), findsOneWidget);
  });
}
