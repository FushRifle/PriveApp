import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
  final Set<int> _visitedTabs = {0};
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

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
    HapticFeedback.mediumImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _feedBloc,
          child: const CreatePostPage(),
        ),
      ),
    );

    if (created == true && context.mounted) {
      _feedBloc.add(RefreshFeed());
    }
  }

  bool get _showBottomBar => _currentIndex != 1;

  double _getBottomPadding(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    if (Platform.isAndroid) {
      return bottomPadding > 0 ? bottomPadding + 8 : 8;
    } else if (Platform.isIOS) {
      return bottomPadding > 0 ? bottomPadding + 4 : 20;
    } else {
      // Web
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
          backgroundColor: backgroundColor,
          extendBody: true,
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: _showBottomBar ? 96 : 0,
                ),
                child: PageStorage(
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
              ),
              if (_showBottomBar)
                const Positioned.fill(
                    child: IgnorePointer(child: _BackgroundGradient())),
              if (_showBottomBar)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      bottom: _getBottomPadding(context),
                      top: 8,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        CurvedNavigationBar(
                          key: _bottomNavigationKey,
                          index: _navBarIndex,
                          height: 60,
                          color: backgroundColor,
                          buttonBackgroundColor: backgroundColor,
                          backgroundColor: Colors.transparent,
                          animationCurve: Curves.easeInOut,
                          animationDuration: const Duration(milliseconds: 600),
                          letIndexChange: (index) => index != 2,
                          items: [
                            _buildNavItem(
                              icon: Icons.home_rounded,
                              isSelected: _navBarIndex == 0,
                              unselectedColor: unselectedColor,
                            ),
                            _buildNavItem(
                              icon: Icons.play_circle_fill_rounded,
                              isSelected: _navBarIndex == 1,
                              unselectedColor: unselectedColor,
                            ),
                            const SizedBox.shrink(),
                            _buildNavItem(
                              icon: Icons.date_range_rounded,
                              isSelected: _navBarIndex == 3,
                              unselectedColor: unselectedColor,
                            ),
                            _buildNavItem(
                              icon: Icons.send_rounded,
                              isSelected: _navBarIndex == 4,
                              unselectedColor: unselectedColor,
                            ),
                          ],
                          onTap: _onNavBarTap,
                        ),
                        Positioned(
                          top: -30,
                          child: _CreateButton(
                            pulseAnimation: _pulseAnimation,
                            onTap: _handleCreatePost,
                          ),
                        ),
                      ],
                    ),
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
    required bool isSelected,
    required Color unselectedColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: isSelected ? 32 : 0,
            height: 3,
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: isSelected ? 44 : 36,
            height: isSelected ? 44 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.border.withOpacity(0.1)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppColors.border.withOpacity(0.3)
                    : Colors.transparent,
                width: isSelected ? 1.5 : 0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 7,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: isSelected ? 30 : 25,
              color: isSelected ? AppColors.primary : unselectedColor,
            ),
          ),
        ],
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

  const _CreateButton({
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
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
                colors: [color.withOpacity(0), color.withOpacity(0.92)])),
      ),
    );
  }
}
