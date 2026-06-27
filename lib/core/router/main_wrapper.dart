import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/ui/pages/main/home/create_post_page.dart';

import 'package:clique/ui/pages/main/chat/inbox_page.dart';
import 'package:clique/ui/pages/main/home/home_page.dart';
import 'package:clique/ui/pages/main/event/events_page.dart';
import 'package:clique/ui/pages/main/reels/reels_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final PageStorageBucket _bucket = PageStorageBucket();
  late final PageController _pageController;
  late final FeedBloc _feedBloc;
  late final StoriesBloc _storiesBloc;
  int _currentIndex = 0;
  bool _isOpeningCreatePost = false;
  final Set<int> _visitedTabs = {0};

  // Navigation bar index mapping:
  // nav[0] -> page[0] (Home)
  // nav[1] -> page[1] (Reels)
  // nav[2] -> Center button (not a page)
  // nav[3] -> page[2] (Events)
  // nav[4] -> page[3] (Chat)
  int _navBarIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _feedBloc = FeedBloc();
    _storiesBloc = StoriesBloc();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _feedBloc.close();
    _storiesBloc.close();
    _pulseController.dispose();
    super.dispose();
  }

  int _pageIndexToNavIndex(int pageIndex) {
    if (pageIndex < 2) return pageIndex;
    return pageIndex + 1;
  }

  int _navIndexToPageIndex(int navIndex) {
    if (navIndex < 2) return navIndex;
    return navIndex - 1;
  }

  void _onTabChanged(int pageIndex) {
    if (_currentIndex == pageIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = pageIndex;
      _visitedTabs.add(pageIndex);
      _navBarIndex = _pageIndexToNavIndex(pageIndex);
    });
    _pageController.jumpToPage(pageIndex);
  }

  void _onNavBarTap(int navIndex) {
    if (navIndex == 2) {
      _handleCreatePost();
      return;
    }

    final pageIndex = _navIndexToPageIndex(navIndex);
    _onTabChanged(pageIndex);
  }

  Future<void> _handleCreatePost() async {
    if (_isOpeningCreatePost) return;
    _isOpeningCreatePost = true;
    HapticFeedback.mediumImpact();
    unawaited(
        _pulseController.forward().then((_) => _pulseController.reverse()));

    try {
      if (!mounted) return;
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'create_post_from_main_wrapper'),
          builder: (_) => BlocProvider.value(
            value: _feedBloc,
            child: const CreatePostPage(),
          ),
        ),
      );

      if (created == true && context.mounted) {
        _feedBloc.add(RefreshFeed());
      }
    } finally {
      _isOpeningCreatePost = false;
    }
  }

  bool get _showBottomBar => true;
  double _getBottomPadding(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    if (kIsWeb) {
      return 8;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return bottomPadding > 0 ? bottomPadding + 8 : 8;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return bottomPadding > 0 ? bottomPadding + 4 : 20;
    } else {
      return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.cardColor;
    final unselectedColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _feedBloc),
        BlocProvider.value(value: _storiesBloc),
      ],
      child: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop || _currentIndex == 0) return;
          _onTabChanged(0);
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
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
                      _navBarIndex = _pageIndexToNavIndex(index);
                    });
                  },
                  children: [
                    _DeferredTab(
                        enabled: _visitedTabs.contains(0),
                        child:
                            const HomePage(key: PageStorageKey('home_page'))),
                    _DeferredTab(
                        enabled: _visitedTabs.contains(1),
                        child: ReelsPage(
                            key: PageStorageKey('reels_page'),
                            onBack: () => _onTabChanged(0),
                            isVisible: _currentIndex == 1)),
                    _DeferredTab(
                        enabled: _visitedTabs.contains(2),
                        child: const _EventTabScope(
                            key: PageStorageKey('events_page'),
                            child: EventsPage())),
                    _DeferredTab(
                        enabled: _visitedTabs.contains(3),
                        child: const _ChatTabScope(
                            key: PageStorageKey('inbox_page'),
                            child: InboxPage())),
                  ],
                ),
              ),
              // Floating bottom bar with glass effect
              if (_showBottomBar)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: _getBottomPadding(context),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // Blurred navigation bar background (no button inside)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.28 : 0.12),
                              blurRadius: 22,
                              spreadRadius: -4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              decoration: BoxDecoration(
                                color: backgroundColor.withOpacity(
                                  isDarkMode ? 0.76 : 0.82,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.72),
                                  width: 0.8,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: SizedBox(
                                height: 50,
                                child: Row(
                                  children: [
                                    _buildNavItem(
                                      icon: Icons.home_rounded,
                                      navIndex: 0,
                                      isSelected: _navBarIndex == 0,
                                      unselectedColor: unselectedColor,
                                    ),
                                    _buildNavItem(
                                      icon: Icons.play_circle_fill_rounded,
                                      navIndex: 1,
                                      isSelected: _navBarIndex == 1,
                                      unselectedColor: unselectedColor,
                                    ),
                                    const Expanded(child: SizedBox.shrink()),
                                    _buildNavItem(
                                      icon: Icons.date_range_rounded,
                                      navIndex: 3,
                                      isSelected: _navBarIndex == 3,
                                      unselectedColor: unselectedColor,
                                    ),
                                    _buildNavItem(
                                      icon: Icons.send_rounded,
                                      navIndex: 4,
                                      isSelected: _navBarIndex == 4,
                                      unselectedColor: unselectedColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Create button – lives outside the clip, can float above the bar
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        top: _currentIndex == 0 ? -25 : 3,
                        child: _CreateButton(
                          pulseAnimation: _pulseAnimation,
                          onTap: _handleCreatePost,
                          isDocked: _currentIndex != 0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int navIndex,
    required bool isSelected,
    required Color unselectedColor,
  }) {
    return Expanded(
      child: Center(
        child: SizedBox(
          width: 46,
          height: 46,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _onNavBarTap(navIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 38,
                height: 38,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  color: isSelected
                      ? AppColors.primary.withOpacity(
                          Theme.of(context).brightness == Brightness.dark
                              ? 0.2
                              : 0.11,
                        )
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.24)
                        : Colors.transparent,
                    width: isSelected ? 0.8 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 9,
                            spreadRadius: -2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  size: isSelected ? 25 : 23,
                  color: isSelected ? AppColors.primary : unselectedColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeferredTab extends StatelessWidget {
  final bool enabled;
  final Widget child;
  const _DeferredTab({required this.enabled, required this.child});
  @override
  Widget build(BuildContext context) =>
      enabled ? child : const SizedBox.shrink();
}

class _ChatTabScope extends StatelessWidget {
  final Widget child;
  const _ChatTabScope({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(),
      child: Builder(
        builder: (context) {
          return BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) {
              return previous.status != current.status ||
                  previous.token != current.token;
            },
            listener: (context, state) {
              final chatBloc = context.read<ChatBloc>();
              if (state.status == AuthStatus.authenticated &&
                  state.token != null) {
                chatBloc.setAuthToken(state.token!);
              } else if (state.status == AuthStatus.unauthenticated) {
                chatBloc.clearAuthToken();
              }
            },
            child: _ChatTabBootstrap(child: child),
          );
        },
      ),
    );
  }
}

class _ChatTabBootstrap extends StatefulWidget {
  final Widget child;

  const _ChatTabBootstrap({required this.child});

  @override
  State<_ChatTabBootstrap> createState() => _ChatTabBootstrapState();
}

class _ChatTabBootstrapState extends State<_ChatTabBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAuthToken());
  }

  void _syncAuthToken() {
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    final chatBloc = context.read<ChatBloc>();

    if (authState.status == AuthStatus.authenticated &&
        authState.token != null) {
      chatBloc.setAuthToken(authState.token!);
    } else if (authState.status == AuthStatus.unauthenticated) {
      chatBloc.clearAuthToken();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _EventTabScope extends StatelessWidget {
  final Widget child;
  const _EventTabScope({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => EventBloc(), child: child);
}

class _CreateButton extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;
  final bool isDocked;

  const _CreateButton({
    required this.pulseAnimation,
    required this.onTap,
    required this.isDocked,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            width: isDocked ? 52 : 68,
            height: isDocked ? 52 : 68,
            child: Center(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkResponse(
                  onTap: onTap,
                  radius: 38,
                  containedInkWell: true,
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    width: isDocked ? 40 : 54,
                    height: isDocked ? 40 : 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(isDocked ? 0.72 : 0.84),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withOpacity(isDocked ? 0.2 : 0.34),
                          blurRadius: isDocked ? 8 : 14,
                          spreadRadius: isDocked ? -1 : 0,
                          offset: Offset(0, isDocked ? 2 : 5),
                        ),
                        BoxShadow(
                          color: AppColors.primary
                              .withOpacity(isDocked ? 0.07 : 0.14),
                          blurRadius: isDocked ? 12 : 22,
                          spreadRadius: isDocked ? -2 : -1,
                          offset: Offset(0, isDocked ? 3 : 9),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                        child: Icon(
                          Icons.add_rounded,
                          size: isDocked ? 24 : 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
