import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';

import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/explore/explore_bloc.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/ui/pages/main/home/create_post_page.dart';

import 'package:clique/ui/pages/main/chat/inbox_page.dart';
import 'package:clique/ui/pages/main/explore/explore_page.dart';
import 'package:clique/ui/pages/main/home/home_page.dart';
import 'package:clique/ui/pages/main/reels/reels_page.dart';

import 'package:clique/ui/widgets/home/clip_status_bar.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper>
    with AutomaticKeepAliveClientMixin {
  final PageStorageBucket _bucket = PageStorageBucket();

  late final PageController _pageController;

  int _currentIndex = 0;

  bool _loadedInitialData = false;

  @override
  bool get wantKeepAlive => true;

  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  void _loadInitialData() {
    if (_loadedInitialData) return;

    _loadedInitialData = true;

    context.read<UserBloc>().add(
          LoadCurrentUser(),
        );
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;

    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });

    _pageController.jumpToPage(index);
  }

  bool get _showBottomBar => _currentIndex != 2;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : Colors.white;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FeedBloc(),
        ),
        BlocProvider(
          create: (_) => StoriesBloc(),
        ),
      ],
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            PageStorage(
              bucket: _bucket,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  if (_currentIndex == index) return;

                  setState(() {
                    _currentIndex = index;
                    _visitedTabs.add(index);
                  });
                },
                children: [
                  _DeferredTab(
                    enabled: _visitedTabs.contains(0),
                    child: const HomePage(
                      key: PageStorageKey('home_page'),
                    ),
                  ),
                  _DeferredTab(
                    enabled: _visitedTabs.contains(1),
                    child: const _ExploreTabScope(
                      key: PageStorageKey('discover_page'),
                      child: DiscoverPage(),
                    ),
                  ),
                  _DeferredTab(
                    enabled: _visitedTabs.contains(2),
                    child: const ReelsPage(
                      key: PageStorageKey('reels_page'),
                    ),
                  ),
                  _DeferredTab(
                    enabled: _visitedTabs.contains(3),
                    child: const _ChatTabScope(
                      key: PageStorageKey('inbox_page'),
                      child: InboxPage(),
                    ),
                  ),
                ],
              ),
            ),
            if (_showBottomBar)
              const Positioned.fill(
                child: IgnorePointer(
                  child: _BackgroundGradient(),
                ),
              ),
            if (_showBottomBar)
              Positioned(
                bottom: 65,
                left: 0,
                right: 0,
                child: Center(
                  child: _CreateButton(),
                ),
              ),
            if (_showBottomBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomNavBar(
                  currentIndex: _currentIndex,
                  backgroundColor: backgroundColor,
                  onChanged: _onTabChanged,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeferredTab extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _DeferredTab({
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return child;
  }
}

class _ExploreTabScope extends StatelessWidget {
  final Widget child;

  const _ExploreTabScope({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExploreBloc(),
      child: child,
    );
  }
}

class _ChatTabScope extends StatelessWidget {
  final Widget child;

  const _ChatTabScope({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(),
      child: child,
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;

  final Color backgroundColor;

  final ValueChanged<int> onChanged;

  const _BottomNavBar({
    required this.currentIndex,
    required this.backgroundColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final unselectedColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          8,
          0,
          8,
          8,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                isDarkMode ? 0.3 : 0.05,
              ),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                _NavItem(
                  index: 0,
                  currentIndex: currentIndex,
                  icon: Icons.home,
                  label: 'Home',
                  unselectedColor: unselectedColor,
                  onTap: onChanged,
                ),
                _NavItem(
                  index: 1,
                  currentIndex: currentIndex,
                  icon: Icons.explore,
                  label: 'Discover',
                  unselectedColor: unselectedColor,
                  onTap: onChanged,
                ),
                _NavItem(
                  index: 2,
                  currentIndex: currentIndex,
                  icon: Icons.play_circle_fill,
                  label: 'Reels',
                  unselectedColor: unselectedColor,
                  onTap: onChanged,
                ),
                _NavItem(
                  index: 3,
                  currentIndex: currentIndex,
                  icon: Icons.message,
                  label: 'Inbox',
                  unselectedColor: unselectedColor,
                  onTap: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;

  final int currentIndex;

  final IconData icon;

  final String label;

  final Color unselectedColor;

  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 180,
                      ),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(
                                0.15,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                    Icon(
                      icon,
                      size: 24,
                      color: isSelected ? AppColors.primary : unselectedColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : unselectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 11,
      child: RepaintBoundary(
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<FeedBloc>(),
                  child: const CreatePostPage(),
                ),
              ),
            );
          },
          child: ClipPath(
            clipper: ClipStatusBar(),
            child: Container(
              height: 110,
              width: 40,
              color: AppColors.primary,
              child: const Icon(
                Icons.add,
                size: 24,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final color = isDarkMode ? AppColors.darkBackground : Colors.white;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0),
              color.withOpacity(0.92),
            ],
          ),
        ),
      ),
    );
  }
}
